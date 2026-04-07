//
//  YggdrasilAccount.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/4/7.
//

import Foundation

public class YggdrasilAccount: Account {
    public let id: UUID
    public private(set) var profile: PlayerProfile
    public let authServer: String
    public let authServerURL: URL
    
    private var _accessToken: String
    private var refreshToken: String
    private var lastRefresh: Date
    
    private enum CodingKeys: String, CodingKey {
        case id, profile, authServer, authServerURL, refreshToken, lastRefresh
        case _accessToken = "accessToken"
    }
    
    public init(
        profile: PlayerProfile,
        authServer: String,
        authServerURL: URL,
        accessToken: String,
        refreshToken: String
    ) {
        self.id = .init()
        self.profile = profile
        self.authServer = authServer
        self.authServerURL = authServerURL
        self._accessToken = accessToken
        self.refreshToken = refreshToken
        self.lastRefresh = .now
    }
    
    public func accessToken() -> String {
        _accessToken
    }
    
    public func refresh() async throws {
        // not implemented
    }
    
    public func shouldRefresh() -> Bool {
        return Date.now.timeIntervalSince(lastRefresh) >= 86400
    }
}
