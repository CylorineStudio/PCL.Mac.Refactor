//
//  LauncherConfig.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/26.
//

import Foundation
import Core

public class LauncherConfig: Codable {
    public static let shared: LauncherConfig = {
        let url: URL = AppURLs.configURL
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
    
    public var minecraftRepositories: [MinecraftRepository]
    
    public init() {
        self.minecraftRepositories = []
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.minecraftRepositories = try container.decodeIfPresent([MinecraftRepository].self, forKey: .minecraftRepositories) ?? []
    }
    
    public static func save(_ config: LauncherConfig = .shared, to url: URL = AppURLs.configURL) throws {
        let data: Data = try JSONEncoder.shared.encode(config)
        try data.write(to: url)
    }
    
    private enum CodingKeys: String, CodingKey {
        case minecraftRepositories
    }
}
