//
//  ModrinthProject.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/16.
//

import Foundation

public enum ModrinthProjectType: String, Codable {
    case mod, modpack, resourcepack, shader
}

public struct ModrinthProject: Decodable, Identifiable {
    public enum Compatibility: String, Decodable {
        case required, optional, unsupported, unknown
    }
    
    private enum CodingKeys: String, CodingKey {
        case projectId = "project_id", type = "project_type"
        case clientSide = "client_side"
        case iconURL = "icon_url"
        case gameVersions = "game_versions"
        
        case id, slug, title, description, downloads, versions, categories, loaders
    }
    
    public let id: String
    public let slug: String
    public let type: ModrinthProjectType
    public let title: String
    public let description: String
    public let iconURL: URL?
    public let downloads: Int
    public let categories: [String]
    public let clientCompatibility: Compatibility
    public let versions: [String]?
    public let gameVersions: [String]?
    public let loaders: [String]?
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? container.decode(String.self, forKey: .projectId)
        self.slug = try container.decode(String.self, forKey: .slug)
        self.type = try container.decode(ModrinthProjectType.self, forKey: .type)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.iconURL = try container.decodeIfPresent(String.self, forKey: .iconURL).flatMap(URL.init(string:))
        self.downloads = try container.decode(Int.self, forKey: .downloads)
        self.categories = try container.decode([String].self, forKey: .categories)
        self.clientCompatibility = try container.decode(Compatibility.self, forKey: .clientSide)
        if let gameVersions: [String] = try container.decodeIfPresent([String].self, forKey: .gameVersions) {
            self.gameVersions = gameVersions
            self.versions = try container.decodeIfPresent([String].self, forKey: .versions)
        } else {
            self.gameVersions = try container.decodeIfPresent([String].self, forKey: .versions)
            self.versions = nil
        }
        self.loaders = try container.decodeIfPresent([String].self, forKey: .loaders)
    }
}

public struct ModrinthVersion: Decodable, Identifiable {
    public enum VersionType: String, Decodable {
        case release, beta, alpha
    }
    
    public struct Dependency: Decodable, Identifiable {
        private enum CodingKeys: String, CodingKey {
            case id = "version_id", projectId = "project_id", dependencyType = "dependency_type"
        }
        
        public let id: String?
        public let projectId: String?
        public let isRequired: Bool
        
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decodeIfPresent(String.self, forKey: .id)
            self.projectId = try container.decodeIfPresent(String.self, forKey: .projectId)
            self.isRequired = try container.decode(String.self, forKey: .dependencyType) == "required"
        }
    }
    
    public struct File: Decodable {
        private enum CodingKeys: String, CodingKey {
            case name = "filename"
            case hashes, url, primary
        }
        
        public let name: String
        public let url: URL
        public let sha1: String?
        public let primary: Bool
        
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.url = try container.decode(URL.self, forKey: .url)
            self.sha1 = try container.decode([String: String].self, forKey: .hashes)["sha1"]
            self.primary = try container.decode(Bool.self, forKey: .primary)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case projectId = "project_id", versionNumber = "version_number", gameVersions = "game_versions", type = "version_type"
        case id, name, downloads, dependencies, loaders, files
    }
    
    public let id: String
    public let projectId: String
    public let name: String
    public let versionNumber: String
    public let downloads: Int
    public let dependencies: [Dependency]
    public let type: VersionType
    public let gameVersions: [String]
    public let loaders: [String]
    public let files: [File]
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.projectId = try container.decode(String.self, forKey: .projectId)
        self.name = try container.decode(String.self, forKey: .name)
        self.versionNumber = try container.decode(String.self, forKey: .versionNumber)
        self.downloads = try container.decode(Int.self, forKey: .downloads)
        self.dependencies = try container.decode([Dependency].self, forKey: .dependencies)
        self.type = try container.decode(VersionType.self, forKey: .type)
        self.gameVersions = try container.decode([String].self, forKey: .gameVersions)
        self.loaders = try container.decode([String].self, forKey: .loaders)
        self.files = try container.decode([File].self, forKey: .files)
    }
}
