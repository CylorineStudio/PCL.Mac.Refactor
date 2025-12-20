//
//  ClientManifest.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/21.
//

import Foundation
import SwiftyJSON

/// https://zh.minecraft.wiki/w/客户端清单文件格式
public class ClientManifest: Decodable {
    public let gameArguments: [Argument]
    public let jvmArguments: [Argument]
    public let assetIndex: AssetIndex
    public let downloads: Downloads
    public let id: String
    public let libraries: [Library]
    public let logging: Logging
    public let mainClass: String
    public let type: String
    
    private enum CodingKeys: String, CodingKey {
        case arguments, assetIndex, downloads, id, libraries, logging, mainClass, type
    }
    
    private enum ArgumentsCodingKeys: String, CodingKey {
        case game, jvm
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let argumentsContainer = try container.nestedContainer(keyedBy: ArgumentsCodingKeys.self, forKey: .arguments)
        self.gameArguments = try argumentsContainer.decode([Argument].self, forKey: .game)
        self.jvmArguments = try argumentsContainer.decode([Argument].self, forKey: .jvm)
        self.assetIndex = try container.decode(AssetIndex.self, forKey: .assetIndex)
        self.downloads = try container.decode(Downloads.self, forKey: .downloads)
        self.id = try container.decode(String.self, forKey: .id)
        self.libraries = try container.decode([Library].self, forKey: .libraries)
        self.logging = try container.decode(Logging.self, forKey: .logging)
        self.mainClass = try container.decode(String.self, forKey: .mainClass)
        self.type = try container.decode(String.self, forKey: .type)
    }
    
    public class Argument: Decodable {
        public let value: [String]
        public let rules: [Rule]
        
        private enum RuledCodingKeys: String, CodingKey {
            case value, rules
        }
        
        public required init(from decoder: any Decoder) throws {
            if let container = try? decoder.singleValueContainer(),
               let value = try? container.decode(String.self) {
                self.value = [value]
                self.rules = []
            } else {
                let container = try decoder.container(keyedBy: RuledCodingKeys.self)
                if let value = try? container.decode([String].self, forKey: .value) {
                    self.value = value
                } else {
                    self.value = [try container.decode(String.self, forKey: .value)]
                }
                self.rules = try container.decode([Rule].self, forKey: .rules)
            }
        }
    }
    
    public class Artifact: Decodable {
        public let path: String
        public let sha1: String?
        public let size: Int?
        public let url: URL
        
        public init(path: String, sha1: String?, size: Int?, url: URL) {
            self.path = path
            self.sha1 = sha1
            self.size = size
            self.url = url
        }
    }
    
    public class AssetIndex: Decodable {
        public let id: String
        public let sha1: String
        public let size: Int
        public let totalSize: Int
        public let url: URL
    }
    
    public class Downloads: Decodable {
        public let client: Download
        public let clientMappings: Download
        public let server: Download
        public let serverMappings: Download
        
        private enum CodingKeys: String, CodingKey {
            case client, server
            case clientMappings = "client_mappings"
            case serverMappings = "server_mappings"
        }
        
        public struct Download: Decodable {
            public let url: URL
            public let size: Int
            public let sha1: String
        }
    }
    
    public class Library: Decodable {
        public let name: String
        public let artifact: Artifact?
        public let rules: [Rule]
        public let isNativesLibrary: Bool
        
        private enum CodingKeys: String, CodingKey {
            case name, downloads, natives, rules
        }
        
        private enum DownloadsCodingKeys: String, CodingKey {
            case artifact, classifiers
        }
        
        public lazy var groupId: String = { String(name.split(separator: ":")[0]) }()
        public lazy var artifactId: String = { String(name.split(separator: ":")[1]) }()
        public lazy var version: String = { String(name.split(separator: ":")[2]) }()
        public lazy var classifier: String? = {
            let parts: [Substring] = name.split(separator: ":")
            return parts.count == 4 ? String(parts[3]) : nil
        }()
        public lazy var isRulesSatisfied: Bool = { rules.allSatisfy { $0.test() } }()
        
        public required init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.isNativesLibrary = container.contains(.natives)
            let downloadsContainer = try? container.nestedContainer(keyedBy: DownloadsCodingKeys.self, forKey: .downloads)
            if !isNativesLibrary {
                self.artifact = try downloadsContainer.unwrap().decode(Artifact.self, forKey: .artifact)
            } else {
                let natives: [String: String] = try container.decode([String: String].self, forKey: .natives)
                if let key = natives["osx"] {
                    let classifiers: [String: Artifact] = try downloadsContainer.unwrap().decode([String: Artifact].self, forKey: .classifiers)
                    self.artifact = try classifiers[key].unwrap()
                } else {
                    self.artifact = nil
                }
            }
            self.rules = try container.decodeIfPresent([Rule].self, forKey: .rules) ?? []
        }
    }
    
    public class Logging: Decodable {
        public let argument: String
        public let file: File
        
        private enum CodingKeys: String, CodingKey { case client }
        private enum ClientCodingKeys: String, CodingKey { case argument, file }
        
        public required init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self).nestedContainer(keyedBy: ClientCodingKeys.self, forKey: .client)
            self.argument = try container.decode(String.self, forKey: .argument)
            self.file = try container.decode(File.self, forKey: .file)
        }
        
        public struct File: Decodable {
            public let id: String
            public let url: URL
            public let size: Int
            public let sha1: String
        }
    }
    
    public class Rule: Decodable {
        public let allow: Bool
        public let osName: String?
        public let osArch: Architecture?
        public let hasFeaturesLimit: Bool
        
        private enum CodingKeys: String, CodingKey {
            case action, features, os
        }
        
        public required init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.allow = try container.decode(String.self, forKey: .action) == "allow"
            let os: [String: String] = try container.decodeIfPresent([String: String].self, forKey: .os) ?? [:]
            self.osName = os["name"]
            self.osArch = os["arch"].flatMap(Architecture.init(rawValue:))
            self.hasFeaturesLimit = container.contains(.features)
        }
        
        /// 判断该 `Rule` 是否通过。
        /// - Returns: 一个布尔值，表示是否通过。
        public func test() -> Bool {
            if let osName, osName != "osx" { return !allow }
            if let osArch, osArch != .arm64 { return !allow } // TODO
            if hasFeaturesLimit { return !allow } // TODO
            return allow
        }
    }
    
    /// 获取所有可用的普通依赖库。
    /// - Returns: 所有可用的普通依赖库。
    public func getLibraries() -> [Library] {
        return libraries.filter { !$0.isNativesLibrary && $0.isRulesSatisfied }
    }
    
    /// 获取所有可用的本地库。
    /// - Returns: 所有可用的本地库。
    public func getNatives() -> [Library] {
        return libraries.filter { $0.isNativesLibrary && $0.isRulesSatisfied }
    }
}
