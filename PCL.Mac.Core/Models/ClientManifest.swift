//
//  ClientManifest.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/11/21.
//

import Foundation
import SwiftyJSON

/// https://zh.minecraft.wiki/w/客户端清单文件格式
public class ClientManifest: Decodable {
    private static let oldVersionFlag: String = "-Dtop.cylorinestudio.cl.OldVersionFlag=1"
    
    public let gameArguments: [Argument]
    public let jvmArguments: [Argument]
    public let assetIndex: AssetIndex!
    public let downloads: Downloads!
    public let id: String
    public let javaVersion: JavaVersion
    public let libraries: [Library]
    public let logging: Logging
    public let mainClass: String
    public let type: String
    
    public let inheritsFrom: String?
    
    // 非标准字段
    public let version: String?
    
    private enum CodingKeys: String, CodingKey {
        case arguments, assetIndex, downloads, id, javaVersion, libraries, logging, mainClass, type
        case minecraftArguments
        case inheritsFrom
        case version
    }
    
    private enum ArgumentsCodingKeys: String, CodingKey {
        case game, jvm
    }
    
    public init(
        gameArguments: [Argument],
        jvmArguments: [Argument],
        assetIndex: AssetIndex?,
        downloads: Downloads?,
        id: String,
        javaVersion: JavaVersion,
        libraries: [Library],
        logging: Logging,
        mainClass: String,
        type: String,
        inheritsFrom: String?,
        version: String?
    ) {
        self.gameArguments = gameArguments
        self.jvmArguments = jvmArguments
        self.assetIndex = assetIndex
        self.downloads = downloads
        self.id = id
        self.javaVersion = javaVersion
        self.libraries = libraries
        self.logging = logging
        self.mainClass = mainClass
        self.type = type
        self.inheritsFrom = inheritsFrom
        self.version = version
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.minecraftArguments) { // 1.12-
            self.gameArguments = try container.decode(String.self, forKey: .minecraftArguments).split(separator: " ").map { .init(value: [String($0)], rules: []) }
            self.jvmArguments = [
                Self.oldVersionFlag,
                "-XX:+UnlockExperimentalVMOptions", "-XX:+UseG1GC", "-XX:-UseAdaptiveSizePolicy", "-XX:-OmitStackTraceInFastThrow",
                "-Djava.library.path=${natives_directory}",
                "-Dorg.lwjgl.system.SharedLibraryExtractPath=${natives_directory}",
                "-Dio.netty.native.workdir=${natives_directory}",
                "-Djna.tmpdir=${natives_directory}",
                "-cp", "${classpath}"
            ].map { .init(value: [$0], rules: []) }
        } else {
            let argumentsContainer = try container.nestedContainer(keyedBy: ArgumentsCodingKeys.self, forKey: .arguments)
            self.gameArguments = try argumentsContainer.decodeIfPresent([Argument].self, forKey: .game) ?? []
            self.jvmArguments = try argumentsContainer.decodeIfPresent([Argument].self, forKey: .jvm) ?? []
        }
        self.assetIndex = try container.decodeIfPresent(AssetIndex.self, forKey: .assetIndex)
        self.downloads = try container.decodeIfPresent(Downloads.self, forKey: .downloads)
        self.id = try container.decode(String.self, forKey: .id)
        self.javaVersion = try container.decodeIfPresent(JavaVersion.self, forKey: .javaVersion) ?? .init(component: "jre-legacy", majorVersion: 8)
        self.libraries = try container.decode([Library].self, forKey: .libraries)
        self.logging = (try? container.decodeIfPresent(Logging.self, forKey: .logging)) ?? .init(
            argument: "-Dlog4j.configurationFile=${path}",
            file: .init(
                id: "client-1.12.xml",
                url: URL(string: "https://piston-data.mojang.com/v1/objects/bd65e7d2e3c237be76cfbef4c2405033d7f91521/client-1.12.xml")!,
                size: 888,
                sha1: "bd65e7d2e3c237be76cfbef4c2405033d7f91521"
            )
        )
        self.mainClass = try container.decode(String.self, forKey: .mainClass)
        self.type = try container.decode(String.self, forKey: .type)
        self.inheritsFrom = try container.decodeIfPresent(String.self, forKey: .inheritsFrom)
        self.version = try container.decodeIfPresent(String.self, forKey: .version)
    }
    
    public class Argument: Decodable {
        public let value: [String]
        public let rules: [ArgumentRule]
        
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
                self.rules = try container.decode([ArgumentRule].self, forKey: .rules)
            }
        }
        
        public init(value: [String], rules: [ArgumentRule]) {
            self.value = value
            self.rules = rules
        }
    }
    
    public class Artifact: Codable {
        public let path: String
        public let sha1: String?
        public let size: Int?
        public let url: URL?
        
        public init(path: String, sha1: String?, size: Int?, url: URL?) {
            self.path = path
            self.sha1 = sha1
            self.size = size
            self.url = url
        }
        
        public required init(from decoder: any Decoder) throws {
            let container: KeyedDecodingContainer<ClientManifest.Artifact.CodingKeys> = try decoder.container(keyedBy: ClientManifest.Artifact.CodingKeys.self)
            self.path = try container.decode(String.self, forKey: ClientManifest.Artifact.CodingKeys.path)
            self.sha1 = try container.decodeIfPresent(String.self, forKey: ClientManifest.Artifact.CodingKeys.sha1)
            self.size = try container.decodeIfPresent(Int.self, forKey: ClientManifest.Artifact.CodingKeys.size)
            self.url = try? container.decodeIfPresent(URL.self, forKey: ClientManifest.Artifact.CodingKeys.url)
        }
        
        public func downloadItem(destinationDirectory: URL) -> DownloadItem? {
            return url.map { DownloadItem(url: $0, destination: destinationDirectory.appending(path: path), sha1: sha1) }
        }
    }
    
    public class AssetIndex: Codable {
        public let id: String
        public let sha1: String
        public let size: Int
        public let totalSize: Int
        public let url: URL
    }
    
    public class Downloads: Decodable {
        public let client: Download
        public let clientMappings: Download?
        public let server: Download?
        public let serverMappings: Download?
        
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
            case name, downloads, natives, rules, url, sha1, size
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
        
        public init(name: String, artifact: Artifact?, rules: [Rule], isNativeLibrary: Bool) {
            self.name = name
            self.artifact = artifact
            self.rules = rules
            self.isNativesLibrary = isNativeLibrary
        }
        
        public required init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.isNativesLibrary = container.contains(.natives)
            self.rules = try container.decodeIfPresent([Rule].self, forKey: .rules) ?? []
            getArtifact: if let downloadsContainer = try? container.nestedContainer(keyedBy: DownloadsCodingKeys.self, forKey: .downloads) {
                if isNativesLibrary {
                    let natives: [String: String] = try container.decode([String: String].self, forKey: .natives)
                    guard let key: String = natives["osx"] else {
                        self.artifact = nil
                        break getArtifact
                    }
                    let classifiers: [String: Artifact] = try downloadsContainer.decode([String: Artifact].self, forKey: .classifiers)
                    self.artifact = try classifiers[key].unwrap()
                } else {
                    self.artifact = try downloadsContainer.decode(Artifact.self, forKey: .artifact)
                }
            } else {
                let url: URL = try container.decodeIfPresent(URL.self, forKey: .url) ?? .init(string: "https://libraries.minecraft.net")!
                let path: String = MavenCoordinateUtils.path(of: name)
                self.artifact = .init(path: path, sha1: nil, size: nil, url: url.appending(path: path))
            }
        }
    }
    
    public class Logging: Decodable {
        public let argument: String
        public let file: File
        
        private enum CodingKeys: String, CodingKey { case client }
        private enum ClientCodingKeys: String, CodingKey { case argument, file }
        
        public init(argument: String, file: File) {
            self.argument = argument
            self.file = file
        }
        
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
        
        private enum CodingKeys: String, CodingKey {
            case action, os
        }
        
        public required init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.allow = try container.decode(String.self, forKey: .action) == "allow"
            let os: [String: String] = try container.decodeIfPresent([String: String].self, forKey: .os) ?? [:]
            self.osName = os["name"]
            self.osArch = os["arch"].map(Architecture.init(rawValue:))
        }
        
        /// 判断该规则是否通过。
        /// - Returns: 一个布尔值，表示是否通过。
        public func test() -> Bool {
            if let osName, osName != "osx" { return !allow }
            if let osArch, osArch != .systemArchitecture() { return !allow }
            return allow
        }
    }
    
    public class ArgumentRule: Rule {
        public let features: [String: Bool]
        
        private enum CodingKeys: String, CodingKey {
            case features
        }
        
        public required init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.features = try container.decodeIfPresent([String: Bool].self, forKey: .features) ?? [:]
            try super.init(from: decoder)
        }
        
        /// 判断该规则是否通过。
        /// - Parameter options: 生成参数时使用的 `LaunchOptions`。
        /// - Returns: 一个布尔值，表示是否通过。
        public func test(with options: LaunchOptions) -> Bool {
            guard super.test() else { return false }
            for (name, value) in features {
                if name == "is_demo_user" && value != options.demo {
                    return !allow
                }
                if [
                    "has_custom_resolution",
                    "has_quick_plays_support",
                    "is_quick_play_singleplayer",
                    "is_quick_play_multiplayer",
                    "is_quick_play_realms"
                ].contains(name) && value { // not implemented
                    return !allow
                }
            }
            return allow
        }
    }
    
    public class JavaVersion: Decodable {
        public let component: String
        public let majorVersion: Int
        
        public init(component: String, majorVersion: Int) {
            self.component = component
            self.majorVersion = majorVersion
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
    
    /// 创建一个新清单，继承本清单的所有属性，并使用指定的 libraries。
    public func setLibraries(to libraries: [Library]) -> ClientManifest {
        return .init(gameArguments: gameArguments, jvmArguments: jvmArguments, assetIndex: assetIndex, downloads: downloads, id: id, javaVersion: javaVersion, libraries: libraries, logging: logging, mainClass: mainClass, type: type, inheritsFrom: inheritsFrom, version: version)
    }
}


// MARK: - Modded 实例处理

public extension ClientManifest {
    func merge(to baseManifest: ClientManifest) -> ClientManifest {
        let isOldVersion: Bool = baseManifest.jvmArguments.contains { $0.value.contains(Self.oldVersionFlag) }
        var librarySet: Set<HashableLibrary> = []
        let libraries: [Library] = (libraries + baseManifest.libraries)
            .filter { $0.isRulesSatisfied && librarySet.insert(.init(from: $0)).inserted }
        librarySet.removeAll()
        
        return .init(
            gameArguments: (isOldVersion ? [] : baseManifest.gameArguments) + gameArguments,
            jvmArguments: (isOldVersion ? [] : baseManifest.jvmArguments) + jvmArguments,
            assetIndex: baseManifest.assetIndex,
            downloads: baseManifest.downloads,
            id: id,
            javaVersion: baseManifest.javaVersion,
            libraries: libraries,
            logging: baseManifest.logging,
            mainClass: mainClass,
            type: baseManifest.type,
            inheritsFrom: nil,
            version: version
        )
    }
    
    private struct HashableLibrary: Hashable {
        private let groupId: String
        private let artifactId: String
        private let classifier: String?
        private let isNativesLibrary: Bool
        
        public init(from library: Library) {
            self.groupId = library.groupId
            self.artifactId = library.artifactId
            self.classifier = library.classifier
            self.isNativesLibrary = library.isNativesLibrary
        }
    }
    
    enum LoadError: LocalizedError {
        case fileNotFound
        case formatError
        case missingParentManifest
        case failedToRead(underlying: Error)
        
        public var errorDescription: String? {
            switch self {
            case .fileNotFound:
                "客户端清单文件不存在。"
            case .formatError:
                "客户端清单格式错误。"
            case .missingParentManifest:
                "未找到客户端清单的父清单。"
            case .failedToRead(let underlying):
                "读取客户端清单失败：\(underlying.localizedDescription)"
            }
        }
    }
    
    /// 从磁盘加载 `ClientManifest`。
    /// - Parameters:
    ///   - url: 客户端清单文件 `URL`。
    ///   - loadParent: 是否加载父清单（`inhertsFrom`）。如果此参数为 `false`，且清单中包含 `inheritsFrom` 键，会抛出 `LoadError.missingParentManifest` 错误。
    /// - Returns: `ClientManifest` 和推测的 Mod Loader。
    /// - Throws: `LoadError`
    static func load(at url: URL, loadParent: Bool = true) throws -> (ClientManifest, ModLoader?) {
        guard FileManager.default.fileExists(atPath: url.path) else { throw LoadError.fileNotFound }
        let data: Data
        do {
            data = try .init(contentsOf: url)
        } catch {
            throw LoadError.failedToRead(underlying: error)
        }
        
        let modLoader: ModLoader?
        guard let str: String = .init(data: data, encoding: .utf8) else { throw LoadError.formatError }
        if str.contains("neoforge") {
            modLoader = .neoforge
        } else if str.contains("forge") {
            modLoader = .forge
        } else if str.contains("fabric") {
            modLoader = .fabric
        } else {
            modLoader = nil
        }
        
        let manifest: ClientManifest = try .load(from: data)
        if let inheritsFrom: String = manifest.inheritsFrom {
            guard loadParent else { throw LoadError.missingParentManifest }
            let parentURLs: [URL] = [
                url.deletingLastPathComponent().appending(path: ".parent/\(inheritsFrom).json"),
                url.deletingLastPathComponent().deletingLastPathComponent().appending(path: "\(inheritsFrom)/\(inheritsFrom).json")
            ]
            for parentURL in parentURLs {
                guard FileManager.default.fileExists(atPath: parentURL.path) else {
                    continue
                }
                let parentManifest: ClientManifest = try .load(at: parentURL, loadParent: false).0
                return (manifest.merge(to: parentManifest), modLoader)
            }
            throw LoadError.missingParentManifest
        }
        return (manifest, modLoader)
    }
    
    static func load(from data: Data) throws -> ClientManifest {
        do {
            return try JSONDecoder.shared.decode(ClientManifest.self, from: data)
        } catch let error as DecodingError {
            err("解析失败：\(error)")
            throw LoadError.formatError
        }
    }
}
