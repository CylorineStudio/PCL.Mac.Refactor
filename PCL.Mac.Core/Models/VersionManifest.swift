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
        private static let aprilFoolVersions: [String] = ["15w14a", "1.rv-pre1", "3d shareware v1.34", "20w14infinite", "22w13oneblockatatime", "23w13a_or_b", "24w14potato", "25w14craftmine"]
        
        public let id: String
        public let type: MinecraftVersion.VersionType
        public let url: URL
        public let time: Date
        public let releaseTime: Date
        
        private enum CodingKeys: CodingKey {
            case id, type, url, time, releaseTime
        }
        
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(String.self, forKey: .id)
                .replacingOccurrences(of: " Pre-Release ", with: "-pre")
            var type: MinecraftVersion.VersionType = try container.decode(MinecraftVersion.VersionType.self, forKey: .type)
            if type == .snapshot && Self.isAprilFoolVersion(id: id, type: type) {
                type = .aprilFool
            }
            self.type = type
            self.url = try container.decode(URL.self, forKey: .url)
            self.time = try container.decode(Date.self, forKey: .time)
            self.releaseTime = try container.decode(Date.self, forKey: .releaseTime)
        }
        
        private static func isAprilFoolVersion(id: String, type: MinecraftVersion.VersionType) -> Bool {
            if aprilFoolVersions.contains(id.lowercased()) { return true }
            return type == .snapshot // 是快照
            && !(id.count == 6 && Array(id)[2] == "w") // 且不是标准快照格式 (如 23w33a)
            && id.rangeOfCharacter(from: .letters) != nil // 至少有一个字母 (筛掉 1.x 与 1.x.x)
            && !id.contains("-pre") && !id.contains("-rc") // 不是 Pre Release 或 Release Candidate
            && !id.contains("snapshot") // 不是新版本号格式的快照（如 26.1-snapshot-1）
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
