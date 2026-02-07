//
//  LauncherConfig.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/26.
//

import Foundation
import Core

class LauncherConfig: Codable {
    public static let shared: LauncherConfig = {
        let url: URL = URLConstants.configURL
        if !FileManager.default.fileExists(atPath: url.path) {
            let config: LauncherConfig = .init()
            log("配置文件不存在，正在创建")
            do {
                try save(config, to: url)
            } catch {
                err("保存配置文件失败：\(error.localizedDescription)")
            }
            return config
        }
        do {
            let data: Data = try Data(contentsOf: url)
            return try JSONDecoder.shared.decode(LauncherConfig.self, from: data)
        } catch {
            err("加载配置文件失败：\(error.localizedDescription)")
            return .init()
        }
    }()
    
    public var minecraftRepositories: [MinecraftRepository] = []
    public var currentRepository: Int?
    public var currentInstance: String?
    public var accounts: [Account] = []
    public var currentAccountId: UUID?
    public var multiplayerDisclaimerAgreed: Bool = false
    public var hasMicrosoftAccount: Bool = false
    public var launchCount: Int = 0
    
    public init() {}
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.minecraftRepositories = try container.decodeIfPresent([MinecraftRepository].self, forKey: .minecraftRepositories) ?? []
        
        if let currentRepository = try container.decodeIfPresent(Int.self, forKey: .currentRepository) {
            self.currentRepository = minecraftRepositories.count > currentRepository ? currentRepository : nil
        } else {
            self.currentRepository = minecraftRepositories.isEmpty ? nil : 0
        }
        
        self.currentInstance = try container.decodeIfPresent(String.self, forKey: .currentInstance)
        self.accounts = (try container.decodeIfPresent([AccountWrapper].self, forKey: .accounts) ?? []).map(\.account)
        if !accounts.isEmpty {
            if let currentAccountId = try container.decodeIfPresent(UUID.self, forKey: .currentAccountId),
               accounts.contains(where: { $0.id == currentAccountId }) {
                self.currentAccountId = currentAccountId
            } else {
                self.currentAccountId = accounts[0].id
            }
        }
        self.multiplayerDisclaimerAgreed = try container.decodeIfPresent(Bool.self, forKey: .multiplayerDisclaimerAgreed) ?? false
        self.hasMicrosoftAccount = try container.decodeIfPresent(Bool.self, forKey: .hasMicrosoftAccount) ?? false
        self.launchCount = try container.decodeIfPresent(Int.self, forKey: .launchCount) ?? 0
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(minecraftRepositories, forKey: .minecraftRepositories)
        try container.encode(currentRepository, forKey: .currentRepository)
        try container.encode(currentInstance, forKey: .currentInstance)
        try container.encode(accounts.map(AccountWrapper.init(_:)), forKey: .accounts)
        try container.encode(currentAccountId, forKey: .currentAccountId)
        try container.encode(multiplayerDisclaimerAgreed, forKey: .multiplayerDisclaimerAgreed)
        try container.encode(hasMicrosoftAccount, forKey: .hasMicrosoftAccount)
        try container.encode(launchCount, forKey: .launchCount)
    }
    
    public static func save(_ config: LauncherConfig = .shared, to url: URL = URLConstants.configURL) throws {
        let data: Data = try JSONEncoder.shared.encode(config)
        try data.write(to: url)
    }
    
    private enum CodingKeys: String, CodingKey {
        case minecraftRepositories
        case currentRepository
        case currentInstance
        case accounts
        case currentAccountId
        case multiplayerDisclaimerAgreed
        case hasMicrosoftAccount
        case launchCount
    }
}
