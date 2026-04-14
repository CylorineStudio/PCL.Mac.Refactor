//
//  OfflineAccount.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/2/2.
//

import Foundation

public class OfflineAccount: Account {
    public let profile: PlayerProfile
    public let id: UUID
    
    public init(name: String, uuid: UUID) {
        self.profile = .init(name: name, id: uuid, properties: [])
        self.id = .init()
    }
    
    public var accessToken: String {
        UUIDUtils.string(of: .init(), withHyphens: false) // 随机 UUID
    }
    
    public func refresh() async throws {}
    
    public func shouldRefresh() -> Bool { false }
}
