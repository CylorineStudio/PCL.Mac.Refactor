//
//  MinecraftVersion.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/24.
//

import Foundation

public class MinecraftVersion: Codable, Comparable, Equatable, Hashable, CustomStringConvertible {
    public let id: String
    public let index: Int
    
    public init(_ id: String) {
        self.id = id
        self.index = CoreState.versionManifest?.ordinal(of: id) ?? .max
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.id = try container.decode(String.self)
        self.index = CoreState.versionManifest?.ordinal(of: id) ?? .max
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.id)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: MinecraftVersion, rhs: MinecraftVersion) -> Bool {
        return lhs.id == rhs.id
    }
    
    public static func < (lhs: MinecraftVersion, rhs: MinecraftVersion) -> Bool {
        return lhs.index > rhs.index
    }
    
    public lazy var description: String = { id }()
    
    public enum VersionType: Decodable {
        case release, snapshot, old, aprilFool
        
        init?(stringValue: String) {
            switch stringValue {
            case "release": self = .release
            case "snapshot": self = .snapshot
            case "old_beta", "old_alpha": self = .old
            default: return nil
            }
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let stringValue: String = try container.decode(String.self)
            guard let result = VersionType(stringValue: stringValue) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "无法解析 VersionType: \(stringValue)"
                )
            }
            self = result
        }
    }
}
