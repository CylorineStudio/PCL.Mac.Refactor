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
    public private(set) var cachedMetadata: String?
    
    private lazy var service: YggdrasilService = .init(authServerURL: authServerURL)
    public private(set) var accessToken: String
    private var clientToken: String
    
    private enum CodingKeys: String, CodingKey {
        case id, profile, authServer, authServerURL, cachedMetadata, accessToken, clientToken
    }
    
    public init(
        profile: PlayerProfile,
        authServer: String,
        authServerURL: URL,
        accessToken: String,
        clientToken: String
    ) {
        self.id = .init()
        self.profile = profile
        self.authServer = authServer
        self.authServerURL = authServerURL
        self.accessToken = accessToken
        self.clientToken = clientToken
    }
    
    public func refresh() async throws {
        let response = try await service.refresh(accessToken, clientToken: clientToken)
        self.accessToken = response.accessToken
        if let profile = response.selectedProfile {
            let fullProfile: PlayerProfile = try await service.fullProfile(for: profile.id)
            self.profile = fullProfile
        }
    }
    
    public func shouldRefresh() async throws -> Bool {
        return try await service.validateToken(accessToken, clientToken: clientToken)
    }
    
    public func fetchMetadata() async throws -> String {
        return try await service.fetchMetadata().encoded
    }
}
