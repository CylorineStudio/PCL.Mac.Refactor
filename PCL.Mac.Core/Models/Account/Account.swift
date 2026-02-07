//
//  Account.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/14.
//

import Foundation

public protocol Account: Codable {
    var profile: PlayerProfile { get }
    var id: UUID { get }
    func accessToken() -> String
    func refresh() async throws
    func shouldRefresh() -> Bool
}

public enum AccountType: String, Codable {
    case offline, microsoft
}

public class AccountWrapper: Codable {
    public let type: AccountType
    public let account: Account
    
    public init(_ account: Account) {
        self.type = account.type
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

public extension Account {
    var type: AccountType {
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
