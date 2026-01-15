//
//  Account.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/14.
//

import Foundation
import Core

protocol Account: Codable {
    var profile: PlayerProfileModel { get }
    func accessToken() throws -> String
    func refresh() async throws
    func shouldRefresh() -> Bool
}

class OfflineAccount: Account {
    public let profile: PlayerProfileModel
    
    public init(name: String, uuid: UUID) {
        self.profile = .init(name: name, id: uuid, properties: [])
    }
    
    public func accessToken() throws -> String {
        return UUIDUtils.string(of: .init(), withHyphens: false) // 随机 UUID
    }
    
    public func refresh() async throws {}
    
    public func shouldRefresh() -> Bool { false }
}

class MicrosoftAccount: Account {
    public private(set) var profile: PlayerProfileModel
    private var _accessToken: String
    private var refreshToken: String
    private var lastRefresh: Date
    
    private enum CodingKeys: String, CodingKey {
        case profile
        case _accessToken = "accessToken"
        case refreshToken
        case lastRefresh
    }
    
    public init(profile: PlayerProfileModel, accessToken: String, refreshToken: String) {
        self.profile = profile
        self._accessToken = accessToken
        self.refreshToken = refreshToken
        self.lastRefresh = .now
    }
    
    public func accessToken() throws -> String {
        _accessToken
    }
    
    public func refresh() async throws {
        let service: MicrosoftAuthService = .init()
        let response = try await service.refresh(token: refreshToken)
        self.profile = response.profile
        self._accessToken = response.accessToken
        self.refreshToken = response.refreshToken
        lastRefresh = .now
    }
    
    public func shouldRefresh() -> Bool {
        return Date.now.timeIntervalSince(lastRefresh) >= 86400
    }
}
