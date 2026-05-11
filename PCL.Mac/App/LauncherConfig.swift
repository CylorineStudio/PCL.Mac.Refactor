//
//  LauncherConfig.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/12/26.
//

import Foundation
import Core

class LauncherConfig: Codable {
    public static let shared: LauncherConfig = {
        let url = URLConstants.configURL
        
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
            let data = try Data(contentsOf: url)
            return try JSONDecoder.shared.decode(LauncherConfig.self, from: data)
        } catch {
            err("加载配置文件失败：\(error.localizedDescription)")
            do {
                if FileManager.default.fileExists(atPath: backupURL.path) {
                    try FileManager.default.removeItem(at: backupURL)
                }
                try FileManager.default.copyItem(at: url, to: backupURL)
                log("备份配置文件成功：\(backupURL.path)")
            } catch {
                err("备份配置文件失败：\(error.localizedDescription)")
            }
            loadError = error
            let config = LauncherConfig()
            try? save(config, to: url)
            return config
        }
    }()
    
    public static let backupURL: URL = URLConstants.applicationSupportURL.appending(path: "config.bak.json")
    public private(set) static var loadError: Error?
    
    public var minecraftRepositories: [MinecraftRepository] = []
    public var currentRepositoryId: UUID?
    public var currentInstance: String?
    public var accounts: [Account] = []
    public var currentAccountId: UUID?
    public var multiplayerDisclaimerAgreed: Bool = false
    public var hasMicrosoftAccount: Bool = false
    public var launchCount: Int = 0
    public var hasEnteredLauncher: Bool = false
    public var multiplayerCustomPeer: String?
    public var ignoreLauncherUpdates: Bool = false
    
    public init() {}
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.minecraftRepositories = try container.decodeIfPresent([MinecraftRepository].self, forKey: .minecraftRepositories) ?? []
        self.currentRepositoryId = try container.decodeIfPresent(UUID.self, forKey: .currentRepositoryId)
        
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
        self.hasEnteredLauncher = try container.decodeIfPresent(Bool.self, forKey: .hasEnteredLauncher) ?? false
        self.multiplayerCustomPeer = try container.decodeIfPresent(String.self, forKey: .multiplayerCustomPeer)
        self.ignoreLauncherUpdates = try container.decodeIfPresent(Bool.self, forKey: .ignoreLauncherUpdates) ?? false
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(minecraftRepositories, forKey: .minecraftRepositories)
        try container.encode(currentRepositoryId, forKey: .currentRepositoryId)
        try container.encode(currentInstance, forKey: .currentInstance)
        try container.encode(accounts.map(AccountWrapper.init(_:)), forKey: .accounts)
        try container.encode(currentAccountId, forKey: .currentAccountId)
        try container.encode(multiplayerDisclaimerAgreed, forKey: .multiplayerDisclaimerAgreed)
        try container.encode(hasMicrosoftAccount, forKey: .hasMicrosoftAccount)
        try container.encode(launchCount, forKey: .launchCount)
        try container.encode(hasEnteredLauncher, forKey: .hasEnteredLauncher)
        try container.encode(multiplayerCustomPeer, forKey: .multiplayerCustomPeer)
        try container.encode(ignoreLauncherUpdates, forKey: .ignoreLauncherUpdates)
    }
    
    public static func save(_ config: LauncherConfig = .shared, to url: URL = URLConstants.configURL) throws {
        let data: Data = try JSONEncoder.shared.encode(config)
        try data.write(to: url)
    }
    
    private enum CodingKeys: String, CodingKey {
        case minecraftRepositories
        case currentRepositoryId
        case currentInstance
        case accounts
        case currentAccountId
        case multiplayerDisclaimerAgreed
        case hasMicrosoftAccount
        case launchCount
        case hasEnteredLauncher
        case multiplayerCustomPeer
        case ignoreLauncherUpdates
    }
}
