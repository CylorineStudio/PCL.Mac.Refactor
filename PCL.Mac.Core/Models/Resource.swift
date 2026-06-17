//
//  Resource.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/5/4.
//

import Foundation

public enum ResourceType: String, Codable {
    case mod, modpack, resourcepack, shader
    
    public var saveDirectory: String? {
        switch self {
        case .mod: "mods"
        case .modpack: nil
        case .resourcepack: "resourcepacks"
        case .shader: "shaderpacks"
        }
    }
}

public struct Resource: Codable, Hashable, Equatable {
    public enum Source: Codable, Hashable, Equatable {
        case modrinth(projectId: String)
        case curseforge(id: Int32)
    }
    
    public enum Icon: Codable, Hashable, Equatable {
        case archiveEntry(path: String, globalHash: String)
        case network(url: URL)
    }
    
    public let id: UUID = .init()
    public let type: ResourceType
    public let name: String
    public let version: String?
    public let description: String?
    public let icon: Icon?
    public let loaders: [ModLoader]
    public let tags: [String]
    public let sources: [Source]
    
    public init(
        type: ResourceType,
        name: String,
        version: String?,
        description: String?,
        icon: Icon?,
        loaders: [ModLoader],
        tags: [String],
        sources: [Source]
    ) {
        self.type = type
        self.name = name
        self.version = version
        self.description = description
        self.icon = icon
        self.loaders = loaders
        self.tags = tags
        self.sources = sources
    }
    
    private enum CodingKeys: CodingKey {
        // 不持久化存储 id
        case type, name, version, description, icon, loaders, tags, sources
    }
}
