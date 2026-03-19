//
//  ProjectListItemModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/18.
//

import Foundation
import Core

struct ProjectListItemModel: Identifiable, Equatable, Hashable {
    public let id: String
    public let title: String
    public let description: String
    public let type: ModrinthProjectType
    public let iconURL: URL?
    public let tags: [String]
    public let supportDescription: String
    public let downloads: String
    public let lastUpdate: String
    
    public init(id: String, title: String, description: String, type: ModrinthProjectType, iconURL: URL?, tags: [String], supportDescription: String, downloads: String, lastUpdate: String) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.iconURL = iconURL
        self.tags = tags
        self.supportDescription = supportDescription
        self.downloads = downloads
        self.lastUpdate = lastUpdate
    }
    
    public init(_ project: ModrinthProject) {
        self.init(
            id: project.id,
            title: project.title,
            description: project.description,
            type: project.type,
            iconURL: project.iconURL,
            tags: project.categories.compactMap { Self.tagMap[$0] },
            supportDescription: Self.generateSupportDescription(for: project),
            downloads: Self.formatDownloads(project.downloads),
            lastUpdate: Self.formatLastUpdate(project.lastUpdate)
        )
    }
    
    public static func formatLastUpdate(_ lastUpdate: Date) -> String {
        let formatter: RelativeDateTimeFormatter = .init()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastUpdate, relativeTo: Date())
            .replacingOccurrences(of: "(\\d+)", with: " $1 ", options: .regularExpression)
    }
    
    public static func formatDownloads(_ downloads: Int) -> String {
        if downloads > 10000 * 10000 {
            return String(format: "%.2f 亿", Double(downloads) / 10000 / 10000)
        } else if downloads > 10000 {
            return "\(downloads / 10000) 万"
        } else {
            return downloads.description
        }
    }
    
    private static func generateSupportDescription(for project: ModrinthProject) -> String {
        var description: String = ""
        
        let modLoaders: [ModLoader] = project.categories.compactMap(ModLoader.init(rawValue:))
        if modLoaders.count == 1 {
            description += "仅 \(modLoaders.first!.description)"
        } else if modLoaders.count < 3 {
            description += modLoaders.map(\.description).joined(separator: " / ")
        }
        if !description.isEmpty { description += " " }
        
        guard let gameVersions = project.gameVersions else {
            return description + "未知"
        }
        let releaseVersions: [String] = gameVersions.filter { CoreState.versionManifest.version(for: $0)?.type == .release }
        guard !releaseVersions.isEmpty else {
            return description + (modLoaders.count == 1 ? "" : "仅") + "快照版本"
        }
        description += generateGameVersionDescription(releaseVersions, latestVersion: CoreState.versionManifest.latestRelease)
        
        return description
    }
    
    private static func generateGameVersionDescription(_ gameVersions: [String], latestVersion: String) -> String {
        guard gameVersions.count > 1 else {
            return gameVersions.isEmpty ? "" : gameVersions[0]
        }
        guard let latestPair: VersionPair = .init(latestVersion) else {
            return "错误"
        }
        
        func rangeDescription(start: VersionPair, end: VersionPair) -> String {
            if start == end {
                return start.description
            } else if end == latestPair {
                return "\(start)+"
            } else {
                return "\(start)~\(end)"
            }
        }
        
        let versionPairs: [VersionPair] = Array(Set(gameVersions.compactMap(VersionPair.init))).sorted()
        
        var ranges: [String] = []
        var start: VersionPair = versionPairs[0]
        var end: VersionPair = start
        for pair in versionPairs.dropFirst() {
            if pair.isNext(to: end) {
                end = pair
            } else {
                ranges.append(rangeDescription(start: start, end: end))
                start = pair
                end = pair
            }
        }
        ranges.append(rangeDescription(start: start, end: end))
        return ranges.reversed().joined(separator: ", ")
    }
    
    private struct VersionPair: Hashable, Equatable, Comparable, CustomStringConvertible {
        public let major: Int
        public let minor: Int
        private let rawVersion: String
        
        public init?(_ version: String) {
            let parts: [Int] = version.split(separator: ".").compactMap { Int($0) }
            guard parts.count >= 2 else { return nil }
            self.major = parts[0]
            self.minor = parts[1]
            self.rawVersion = version
        }
        
        public func isNext(to another: VersionPair) -> Bool {
            if self == another { return false }
            // 确保版本号格式相同
            if (self.major == 1 && another.major != 1) || (another.major == 1 && self.major != 1) {
                let boundaryVersions: [String] = ["1.21.11", "26.1"]
                return boundaryVersions.contains(self.rawVersion) && boundaryVersions.contains(another.rawVersion)
            }
            
            if self.major == another.major {
                return abs(self.minor - another.minor) == 1
            } else {
                if self.minor == 1 {
                    return another.major == self.major - 1 && another.isYearlyLatest()
                } else if another.minor == 1 {
                    return self.major == another.major - 1 && self.isYearlyLatest()
                } else {
                    return false
                }
            }
        }
        
        /// 检查当前版本是不是该年份（26）的最后一个版本（正式更新，例如 26.4）。
        /// 在该版本号的格式为旧版格式时，此函数一定会返回 `false`。
        public func isYearlyLatest(_ manifest: VersionManifest = CoreState.versionManifest) -> Bool {
            if major == 1 { return false }
            let yearlyLatest: VersionPair? = manifest.versions
                .filter { $0.type == .release && $0.id.starts(with: "\(major).") }
                .first.flatMap { VersionPair($0.id) }
            return self == yearlyLatest
            
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(major)
            hasher.combine(minor)
            // 忽略 rawVersion
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.major == rhs.major && lhs.minor == rhs.minor // 忽略 rawVersion
        }
        
        public static func < (lhs: Self, rhs: Self) -> Bool {
            return lhs.major > rhs.major ? false : lhs.minor < rhs.minor ? true : false
        }
        
        public var description: String {
            "\(major).\(minor)"
        }
    }
    
    private static let tagMap: [String: String] = [
        "technology": "科技",
        "magic": "魔法",
        "adventure": "冒险",
        "utility": "实用",
        "optimization": "性能优化",
        "vanilla-like": "原版风",
        "realistic": "写实风",
        "worldgen": "世界元素",
        "food": "食物/烹饪",
        "game-mechanics": "游戏机制",
        "transportation": "运输",
        "storage": "仓储",
        "decoration": "装饰",
        "mobs": "生物",
        "equipment": "装备",
        "social": "服务器",
        "library": "支持库",
        "multiplayer": "多人",
        "challenging": "硬核",
        "combat": "战斗",
        "quests": "任务",
        "kitchen-sink": "水槽包",
        "lightweight": "轻量",
        "simplistic": "简洁",
        "tweaks": "改良",
        "8x-": "极简",
        "16x": "16x",
        "32x": "32x",
        "48x": "48x",
        "64x": "64x",
        "128x": "128x",
        "256x": "256x",
        "512x+": "超高清",
        "audio": "含声音",
        "fonts": "含字体",
        "models": "含模型",
        "gui": "含 UI",
        "locale": "含语言",
        "core-shaders": "核心着色器",
        "modded": "兼容 Mod",
        "fantasy": "幻想风",
        "semi-realistic": "半写实风",
        "cartoon": "卡通风",
        "colored-lighting": "彩色光照",
        "path-tracing": "路径追踪",
        "pbr": "PBR",
        "reflections": "反射",
        "iris":" Iris",
        "optifine": "OptiFine",
        "vanilla": "原版可用"
    ]
}
