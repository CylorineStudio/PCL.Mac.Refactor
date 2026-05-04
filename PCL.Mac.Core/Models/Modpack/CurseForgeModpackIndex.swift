//
//  CurseForgeModpackIndex.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/5/2.
//

import Foundation

public struct CurseForgeModpackIndex: Decodable {
    public struct File: Decodable {
        public let projectId: Int
        public let fileId: Int
        public let fileName: String?
        public let url: URL?
        public let required: Bool
        
        private enum CodingKeys: String, CodingKey {
            case fileName, url, required
            case projectId = "projectID", fileId = "fileID"
        }
    }
    
    private struct ModLoader: Decodable {
        public let id: String
        public let primary: Bool
    }
    
    public let manifestType: String
    public let manifestVersion: Int
    
    public let name: String
    public let version: String
    public let author: String?
    public let overridesDirectory: String?
    public let minecraftVersion: String
    public let modLoader: (String, String)?
    public let files: [File]
    
    private enum CodingKeys: String, CodingKey {
        case manifestType, manifestVersion, name, version, author, minecraft, overrides, files
    }
    
    private enum MinecraftCodingKeys: CodingKey {
        case version, modLoaders
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.manifestType = try container.decode(String.self, forKey: .manifestType)
        self.manifestVersion = try container.decode(Int.self, forKey: .manifestVersion)
        self.name = try container.decode(String.self, forKey: .name)
        self.version = try container.decode(String.self, forKey: .version)
        self.author = try container.decodeIfPresent(String.self, forKey: .author)
        self.overridesDirectory = try container.decodeIfPresent(String.self, forKey: .overrides)
        self.files = try container.decodeIfPresent([File].self, forKey: .files) ?? []
        
        let minecraftContainer = try container.nestedContainer(keyedBy: MinecraftCodingKeys.self, forKey: .minecraft)
        self.minecraftVersion = try minecraftContainer.decode(String.self, forKey: .version)
        self.modLoader = try minecraftContainer.decodeIfPresent([ModLoader].self, forKey: .modLoaders)?
            .first(where: { $0.primary })
            .flatMap { loader in
                let parts = loader.id.split(separator: "-", maxSplits: 1).map(String.init)
                guard parts.count == 2 else { return nil }
                return (parts[0], parts[1])
            }
    }
}
