//
//  ModpackIndex.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/5/2.
//

import Foundation

public struct ModpackIndex {
    public struct File {
        public let url: URL
        public let path: String
        public let checksums: [String: String]
    }
    
    public let format: String
    
    public let name: String
    public let version: String
    public let author: String?
    public let description: String?
    
    public let minecraftVersion: MinecraftVersion
    public let modLoader: (ModLoader, String)?
    public let files: [File]
    public let overridesDirectories: [String]
    
    public var dependencyInfo: String {
        var info = "Minecraft \(minecraftVersion)"
        if let modLoader {
            info += ", \(modLoader.0.description) \(modLoader.1)"
        }
        return info
    }
}
