//
//  MicrosoftAuthService.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/14.
//

import Foundation
import SwiftyJSON

public class MicrosoftAuthService {
    public private(set) var pollCount: Int?
    public private(set) var pollInterval: Int?
    private let clientID: String = "dd28b3f2-1db5-49b7-9228-99fdb46dfaca"
    private var deviceCode: String?
    private var oAuthToken: String?
    private var refreshToken: String?
    
    public init() {}
    
    /// 开始登录并获取设备码。
    /// - Returns: 用户授权代码和 `URL`。
    public func start() async throws -> AuthorizationCode {
        let json = try await post(
            "https://login.microsoftonline.com/consumers/oauth2/v2.0/devicecode",
            [
                "client_id": clientID
            ],
            encodeMethod: .urlEncoded
        )
        self.deviceCode = json["device_code"].stringValue
        let expiresIn: Int = json["expires_in"].intValue
        let interval: Int = json["interval"].intValue
        self.pollCount = expiresIn / interval
        self.pollInterval = interval
        return .init(
            code: json["user_code"].stringValue,
            verificationURL: URL(string: json["verification_uri"].stringValue) ?? URL(string: "https://microsoft.com/link")!
        )
    }
    
    /// 轮询用户验证状态。
    /// - Returns: 用户是否完成了验证。
    public func poll() async throws -> Bool {
        guard let deviceCode else {
            throw Error.internalError
        }
        let json: JSON = try await post(
            "https://login.microsoftonline.com/consumers/oauth2/v2.0/token",
            [
                "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
                "client_id": clientID,
                "device_code": deviceCode
            ],
            encodeMethod: .urlEncoded
        )
        if let accessToken = json["accessToken"].string {
            self.oAuthToken = accessToken
            return true
        }
        return false
    }
    
    /// 完成后续登录步骤。
    /// - Returns: 包含玩家档案（不包含属性）、Minecraft access token 和 OAuth refresh token 的结构体。
    public func authenticate() async throws -> MinecraftAuthResponse {
        guard let oAuthToken, let refreshToken else {
            throw Error.internalError
        }
        let xboxLiveAuthResponse: XboxLiveAuthResponse = try await authenticateXBL(with: oAuthToken)
        let xstsAuthResponse: XboxLiveAuthResponse = try await authorizeXSTS(with: xboxLiveAuthResponse.token)
        let minecraftToken: String = try await loginMinecraft(with: xstsAuthResponse)
        guard let profile: PlayerProfileModel = try await getMinecraftProfile(with: minecraftToken) else {
            throw Error.notPurchased
        }
        return .init(profile: profile, accessToken: minecraftToken, refreshToken: refreshToken)
    }
    
    public struct AuthorizationCode {
        public let code: String
        public let verificationURL: URL
    }
    
    public struct MinecraftAuthResponse {
        public let profile: PlayerProfileModel
        public let accessToken: String
        public let refreshToken: String
    }
    
    public enum Error: LocalizedError {
        case apiError(description: String)
        case internalError
        case notPurchased
        
        public var errorDescription: String? {
            switch self {
            case .apiError(let description):
                "调用 API 失败：\(description)"
            case .internalError:
                "发生内部错误。"
            case .notPurchased:
                "你还没有购买 Minecraft！"
            }
        }
    }
    
    
    private struct XboxLiveAuthResponse {
        public let token: String
        public let uhs: String
    }
    
    private func post(_ url: URLConvertible, _ body: [String: Any], encodeMethod: Requests.EncodeMethod = .json) async throws -> JSON {
        let json: JSON = try await Requests.post(url, body: body, using: encodeMethod).json()
        if let error: String = json["error"].string,
           error != "authorization_pending" && error != "slow_down" {
            let description: String = json["error_description"].string ?? json["errorMessage"].stringValue
            err("调用 API 失败：\(error)，错误描述：\(description)")
            throw Error.apiError(description: description)
        }
        return json
    }
    
    private func authenticateXBL(with accessToken: String) async throws -> XboxLiveAuthResponse {
        let json: JSON = try await post(
            "https://user.auth.xboxlive.com/user/authenticate",
            [
                "Properties": [
                    "AuthMethod": "RPS",
                    "SiteName": "user.auth.xboxlive.com",
                    "RpsTicket": "d=\(accessToken)"
                ],
                "RelyingParty": "http://auth.xboxlive.com",
                "TokenType": "JWT"
            ]
        )
        return XboxLiveAuthResponse(token: json["Token"].stringValue, uhs: json["DisplayClaims"]["xui"].arrayValue[0]["uhs"].stringValue)
    }
    
    private func authorizeXSTS(with accessToken: String) async throws -> XboxLiveAuthResponse {
        let json: JSON = try await post(
            "https://xsts.auth.xboxlive.com/xsts/authorize",
            [
                "Properties": [
                    "SandboxId": "RETAIL",
                    "UserTokens": [
                        accessToken
                    ]
                ],
                "RelyingParty": "rp://api.minecraftservices.com/",
                "TokenType": "JWT"
            ]
        )
        return XboxLiveAuthResponse(token: json["Token"].stringValue, uhs: json["DisplayClaims"]["xui"].arrayValue[0]["uhs"].stringValue)
    }
    
    private func loginMinecraft(with xstsAuthResponse: XboxLiveAuthResponse) async throws -> String {
        let json: JSON = try await post(
            "https://api.minecraftservices.com/authentication/login_with_xbox",
            [
                "identityToken": "XBL3.0 x=\(xstsAuthResponse.uhs);\(xstsAuthResponse.token)"
            ]
        )
        return json["access_token"].stringValue
    }
    
    private func getMinecraftProfile(with token: String) async throws -> PlayerProfileModel? {
        let response = try await Requests.get(
            "https://api.minecraftservices.com/minecraft/profile",
            headers: [
                "Authorization": "Bearer \(token)"
            ]
        )
        let json: JSON = try response.json()
        if let error = json["error"].string {
            if error == "NOT_FOUND" {
                return nil
            } else {
                err("发生未知错误：\(error) \(json["errorMessage"].stringValue)")
                throw Error.apiError(description: json["errorMessage"].stringValue)
            }
        }
        do {
            return try JSONDecoder.shared.decode(PlayerProfileModel.self, from: response.data)
        } catch {
            err("解析 PlayerProfile 失败：\(String(data: response.data, encoding: .utf8) ?? "（解码失败）")")
            throw Error.internalError
        }
    }
}
