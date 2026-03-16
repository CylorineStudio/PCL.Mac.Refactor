//
//  ModrinthAPIClient.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/16.
//

import Foundation

public class ModrinthAPIClient {
    public static let shared: ModrinthAPIClient = .init(apiRoot: URL(string: "https://api.modrinth.com")!)
    
    private let apiRoot: URL
    
    private init(apiRoot: URL) {
        self.apiRoot = apiRoot
    }
    
    /// 搜索 Modrinth 项目。
    /// - Parameters:
    ///   - type: 项目类型（`ProjectType`）。
    ///   - query: 搜索关键词。
    ///   - gameVersion: 过滤游戏版本。
    ///   - pageIndex: 页码，从 0 开始。
    ///   - limit: 返回结果数量上限。
    /// - Returns: 包含搜索结果和分页信息的 `SearchResponse`。
    public func search(
        type: ProjectType,
        _ query: String?,
        forVersion gameVersion: String?,
        pageIndex: Int = 0,
        limit: Int = 40
    ) async throws -> SearchResponse {
        var facets: [[String]] = [["project_type:\(type)"]]
        if let gameVersion {
            facets.append(["versions:\(gameVersion)"])
        }
        let facetsString: String = String(data: try JSONSerialization.data(withJSONObject: facets), encoding: .utf8)!
        
        let response = try await Requests.get(
            apiRoot.appending(path: "/v2/search"),
            params: [
                "query": query == "" ? nil : query,
                "facets": facetsString,
                "limit": String(describing: limit),
                "offset": String(describing: pageIndex * limit)
            ]
        )
        return try response.decode(SearchResponse.self)
    }
    
    /// 获取指定 id 或 slug 对应的 `Project`。
    /// - Parameter slug: 指定 id 或 slug。
    /// - Returns: 对应的 `Project`。
    public func project(_ slug: String) async throws -> Project {
        return try await Requests.get(apiRoot.appending(path: "/v2/project/\(slug)")).decode(Project.self)
    }
    
    /// 获取指定 project 的所有 `Version`。
    /// - Parameter slug: 指定 project 的 id 或 slug。
    /// - Returns: 该 project 的所有 `Version`（`[Version]`）。
    public func versions(ofProject slug: String) async throws -> [Version] {
        return try await Requests.get(apiRoot.appending(path: "/v2/project/\(slug)/version")).decode([Version].self)
    }
    
    /// 获取指定 project 的所有 `Version`。
    /// - Parameter slug: 指定 `Project`。
    /// - Returns: 该 project 的所有 `Version`（`[Version]`）。
    public func versions(ofProject project: Project) async throws -> [Version] {
        return try await versions(ofProject: project.slug)
    }
    
    /// 获取指定 id 对应的 `Version`。
    /// - Parameter slug: 指定 id。
    /// - Returns: 对应的 `Version`。
    public func version(_ id: String) async throws -> Version {
        return try await Requests.get(apiRoot.appending(path: "/v2/version/\(id)")).decode(Version.self)
    }
    
    /// 根据文件的 SHA-1 哈希值查询 `Version`。
    /// - Parameter hash: 文件的 SHA-1 哈希值。
    /// - Returns: 如果找到则返回对应的 `Version`，否则返回 `nil`。
    public func version(ofHash hash: String) async throws -> Version? {
        let response = try await Requests.get(apiRoot.appending(path: "/v2/version_file/\(hash)"))
        if response.statusCode == 404 { return nil }
        return try response.decode(Version.self)
    }
    
    /// 批量根据文件的 SHA-1 查询 `Version`。
    /// - Parameter hashes: 所有文件的 SHA-1 哈希值（`[String]`）。
    /// - Returns: 包含所有找到的 `Version` 的 dict。
    public func versions(ofHashes hashes: [String]) async throws -> [String: Version] {
        return try await Requests.post(
            apiRoot.appending(path: "/v2/version_files"),
            body: [
                "hashes": hashes,
                "algorithm": "sha1"
            ],
            using: .json
        ).decode([String: Version].self)
    }
    
    // MARK: - 数据模型
    
    public enum ProjectType: String, Codable {
        case mod, modpack, resourcepack, shader
    }
    
    public struct Project: Decodable, Identifiable {
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
        public let type: ProjectType
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
            self.type = try container.decode(ProjectType.self, forKey: .type)
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
    
    public struct Version: Decodable, Identifiable {
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
    
    public struct SearchResponse: Decodable {
        private enum CodingKeys: String, CodingKey {
            case hits, offset, limit, totalHits = "total_hits"
        }
        
        public let hits: [Project]
        public let offset: Int
        public let limit: Int
        public let totalHits: Int
    }
}
