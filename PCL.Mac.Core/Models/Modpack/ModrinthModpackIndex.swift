//
//  ModrinthModpackIndex.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/22.
//

import Foundation

public struct ModrinthModpackIndex: Codable {
    public struct File: Codable {
        public let path: String
        public let hashes: [String: String]
        public let env: [Side: ModrinthCompatibility]?
        public let downloads: [URL]
        
        private enum CodingKeys: CodingKey {
            case path, hashes, env, downloads
        }
        
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.path = try container.decode(String.self, forKey: .path)
            self.hashes = try container.decode([String: String].self, forKey: .hashes)
            if let rawEnv: [String: ModrinthCompatibility] = try container.decodeIfPresent([String: ModrinthCompatibility].self, forKey: .env) {
                self.env = Dictionary(
                    uniqueKeysWithValues: rawEnv.compactMap { key, value in
                        guard let side = Side(rawValue: key) else { return nil }
                        return (side, value)
                    }
                )
            } else {
                self.env = nil
            }
            self.downloads = try container.decode([URL].self, forKey: .downloads)
        }
    }
    
    public struct Dependencies: Codable, CustomStringConvertible {
        public let minecraft: String
        public let forge: String?
        public let neoforge: String?
        public let fabricLoader: String?
        public let quiltLoader: String?
        
        private enum CodingKeys: String, CodingKey {
            case minecraft, forge, neoforge
            case fabricLoader = "fabric-loader", quiltLoader = "quilt-loader"
        }
        
        public var description: String {
            var description: String = "Minecraft \(minecraft)"
            if let forge {
                description += ", Forge \(forge)"
            } else if let neoforge {
                description += ", NeoForge \(neoforge)"
            } else if let fabricLoader {
                description += ", Fabric \(fabricLoader)"
            } else if let quiltLoader {
                description += ", Quilt \(quiltLoader)"
            }
            return description
        }
    }
    
    public let formatVersion: Int
    public let name: String
    public let summary: String?
    public let game: String
    public let versionId: String
    public let files: [File]
    public let dependencies: Dependencies
}
