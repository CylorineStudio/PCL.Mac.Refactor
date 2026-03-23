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
        public let env: [Side: ModrinthCompatibility]
        public let downloads: [URL]
    }
    
    public struct Dependencies: Codable {
        public let minecraft: String
        public let forge: String?
        public let neoforge: String?
        public let fabricLoader: String?
        public let quiltLoader: String?
        
        private enum CodingKeys: String, CodingKey {
            case minecraft, forge, neoforge
            case fabricLoader = "fabric-loader", quiltLoader = "quilt-loader"
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
