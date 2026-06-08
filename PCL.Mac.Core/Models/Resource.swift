//
//  Resource.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/5/4.
//

import Foundation

public enum ProjectType: String, Codable {
    case mod, modpack, resourcepack, shader
}

public enum ResourceIcon: Codable, Hashable, Equatable {
    case archiveEntry(path: String, globalHash: String)
    case network(url: URL)
}

public struct Mod: Codable, Hashable, Equatable {
    public enum Source: Codable, Hashable, Equatable {
        case modrinth(projectId: String)
        case curseforge(id: Int32)
    }
    
    public let id: UUID = .init()
    public let name: String
    public let version: String
    public let description: String?
    public let icon: ResourceIcon?
    public let loaders: [ModLoader]
    public let sources: [Source]
    
    public init(name: String, version: String, description: String?, icon: ResourceIcon?, loaders: [ModLoader], sources: [Source]) {
        self.name = name
        self.version = version
        self.description = description
        self.icon = icon
        self.loaders = loaders
        self.sources = sources
    }
    
    private enum CodingKeys: CodingKey {
        // 不持久化存储 id
        case name, version, description, icon, loaders, sources
    }
}
