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
    
    public enum DependencyType: String, Codable {
        case minecraft, forge, neoforge, fabric = "fabric-loader", quilt = "quilt-loader"
    }
    
    public let formatVersion: Int
    public let name: String
    public let summary: String?
    public let game: String
    public let versionId: String
    public let dependencies: [DependencyType: String]
}
