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
    var id: UUID { get }
    func accessToken() throws -> String
    func refresh() async throws
    func shouldRefresh() -> Bool
}

class OfflineAccount: Account {
    public let profile: PlayerProfileModel
    public let id: UUID
    
    public init(name: String, uuid: UUID) {
        self.profile = .init(name: name, id: uuid, properties: [])
        self.id = .init()
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
    public let id: UUID
    
    private enum CodingKeys: String, CodingKey {
        case profile
        case _accessToken = "accessToken"
        case refreshToken
        case lastRefresh
        case id
    }
    
    public init(profile: PlayerProfileModel, accessToken: String, refreshToken: String) {
        self.profile = profile
        self._accessToken = accessToken
        self.refreshToken = refreshToken
        self.lastRefresh = .now
        self.id = .init()
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

class AccountWrapper: Codable {
    public enum AccountType: String, Codable {
        case offline, microsoft
        
        public var localized: String {
            switch self {
            case .offline: "离线账号"
            case .microsoft: "正版账号"
            }
        }
    }
    
    public let type: AccountType
    public let account: Account
    
    public init(_ account: Account) {
        self.type = account.type()
        self.account = account
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case account
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(AccountType.self, forKey: .type)
        switch type {
        case .offline:
            self.account = try container.decode(OfflineAccount.self, forKey: .account)
        case .microsoft:
            self.account = try container.decode(MicrosoftAccount.self, forKey: .account)
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(account, forKey: .account)
    }
}

extension Account {
    func type() -> AccountWrapper.AccountType {
        switch self {
        case is OfflineAccount:
            .offline
        case is MicrosoftAccount:
            .microsoft
        default:
            fatalError() // unreachable
        }
    }
}
