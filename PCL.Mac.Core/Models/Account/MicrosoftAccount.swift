//
//  MicrosoftAccount.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/2/2.
//

import Foundation

public class MicrosoftAccount: Account {
    public private(set) var profile: PlayerProfile
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
    
    public init(profile: PlayerProfile, accessToken: String, refreshToken: String) {
        self.profile = profile
        self._accessToken = accessToken
        self.refreshToken = refreshToken
        self.lastRefresh = .now
        self.id = .init()
    }
    
    public func accessToken() -> String {
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
