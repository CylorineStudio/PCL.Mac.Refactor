//
//  MojangJavaManifest.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/11.
//

import Foundation

public struct MojangJavaManifest: Decodable {
    public let files: [String: File]
    
    private enum CodingKeys: String, CodingKey {
        case files
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.files = try container.decode([String: File].self, forKey: .files)
    }
    
    public enum File: Decodable {
        case directory
        case file(url: URL, sha1: String?, size: Int?, executable: Bool)
        case link(target: String)
        
        private enum CodingKeys: String, CodingKey {
            case type
            case downloads, executable
            case target
        }
        
        private enum DownloadsCodingKeys: String, CodingKey { case raw, lzma }
        private enum DownloadCodingKeys: String, CodingKey {
            case url, sha1, size
        }
        
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type: String = try container.decode(String.self, forKey: .type)
            switch type {
            case "directory":
                self = .directory
            case "file":
                let downloadContainer = try container.nestedContainer(keyedBy: DownloadsCodingKeys.self, forKey: .downloads).nestedContainer(keyedBy: DownloadCodingKeys.self, forKey: .raw)
                self = .file(
                    url: try downloadContainer.decode(URL.self, forKey: .url),
                    sha1: try downloadContainer.decodeIfPresent(String.self, forKey: .sha1),
                    size: try downloadContainer.decodeIfPresent(Int.self, forKey: .size),
                    executable: try container.decodeIfPresent(Bool.self, forKey: .executable) ?? false
                )
            case "link":
                self = .link(target: try container.decode(String.self, forKey: .target))
            default:
                throw DecodingError.typeMismatch(String.self, .init(codingPath: decoder.codingPath, debugDescription: "Unexpected type '\(type)'"))
            }
        }
    }
}

public struct MojangJavaList: Decodable {
    public let entries: [String: [JavaDownload]]
    
    public init(from decoder: any Decoder) throws {
        self.entries = try decoder.singleValueContainer().decode([String: [String: [JavaDownload]]].self)
            .mapValues { $0.compactMap(\.value.first) }
    }
    
    public struct JavaDownload: Decodable {
        public let manifestURL: URL
        public let version: String
        public let releaseTime: Date
        
        private enum CodingKeys: String, CodingKey {
            case manifest, version
        }
        private enum ManifestCodingKeys: String, CodingKey { case url }
        private enum VersionCodingKeys: String, CodingKey { case name, released }
        
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.manifestURL = try container.nestedContainer(keyedBy: ManifestCodingKeys.self, forKey: .manifest).decode(URL.self, forKey: .url)
            let versionContainer = try container.nestedContainer(keyedBy: VersionCodingKeys.self, forKey: .version)
            self.version = try versionContainer.decode(String.self, forKey: .name)
            self.releaseTime = try versionContainer.decode(Date.self, forKey: .released)
        }
    }
}
