//
//  VersionManifest.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/12/2.
//

import Foundation
import SwiftyJSON

/// https://zh.minecraft.wiki/w/Version_manifest.json#JSON格式
public struct VersionManifest: Decodable {
    public let latestRelease: String
    public let latestSnapshot: String?
    public let versions: [Version]
    
    private enum CodingKeys: String, CodingKey {
        case latest, versions
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latest: Latest = try container.decode(Latest.self, forKey: .latest)
        self.latestRelease = latest.release
        self.latestSnapshot = latest.release == latest.snapshot ? nil : latest.snapshot
        self.versions = try container.decode([Version].self, forKey: .versions)
    }
    
    public struct Version: Decodable, Hashable {
        public let id: String
        public let type: MinecraftVersion.VersionType
        public let url: URL
        public let time: Date
        public let releaseTime: Date
        
        private enum CodingKeys: CodingKey {
            case id, type, url, time, releaseTime
        }
        
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: VersionManifest.Version.CodingKeys.self)
            self.id = try container.decode(String.self, forKey: VersionManifest.Version.CodingKeys.id)
                .replacingOccurrences(of: " Pre-Release ", with: "-pre")
            self.type = try container.decode(MinecraftVersion.VersionType.self, forKey: VersionManifest.Version.CodingKeys.type)
            self.url = try container.decode(URL.self, forKey: VersionManifest.Version.CodingKeys.url)
            self.time = try container.decode(Date.self, forKey: VersionManifest.Version.CodingKeys.time)
            self.releaseTime = try container.decode(Date.self, forKey: VersionManifest.Version.CodingKeys.releaseTime)
        }
    }
    
    /// 根据版本号获取在 `versions` 中的顺序（版本号越大，返回值越小）。
    /// - Parameter id: 版本号。
    /// - Returns: 在 `versions` 中的顺序。
    public func ordinal(of id: String) -> Int {
        return versions.firstIndex(where: { $0.id == id }) ?? -1
    }
    
    /// 获取版本号对应的 `Version` 对象。
    /// - Parameter id: 版本号。
    /// - Returns: `Version` 对象。
    public func version(for id: String) -> Version? {
        return versions.first(where: { $0.id == id })
    }
    
    // MARK: - Decodables
    
    private struct Latest: Decodable {
        public let release: String
        public let snapshot: String
    }
}
