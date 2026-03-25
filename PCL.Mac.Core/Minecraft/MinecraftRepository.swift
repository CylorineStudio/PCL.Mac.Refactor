//
//  MinecraftRepository.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/12/26.
//

import Foundation

/// Minecraft 仓库（`.minecraft`）。
public class MinecraftRepository: ObservableObject, Codable, Hashable, Equatable {
    @Published public var name: String
    @Published public var url: URL
    @Published public var instances: [MinecraftInstance]?
    @Published public var errorInstances: [ErrorInstance]?
    
    public lazy var assetsURL: URL = { url.appending(path: "assets") }()
    public lazy var librariesURL: URL = { url.appending(path: "libraries") }()
    public lazy var versionsURL: URL = { url.appending(path: "versions") }()
    
    public init(name: String, url: URL, instances: [MinecraftInstance]? = nil) {
        self.name = name
        self.url = url
        self.instances = instances
    }
    
    /// 创建必要目录。
    public func createDirectories() throws {
        let fileManager: FileManager = .default
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: assetsURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: librariesURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: versionsURL, withIntermediateDirectories: true)
    }
    
    /// 加载该仓库中的所有实例。
    /// 只会在读取目录失败时抛出错误。
    public func load() throws {
        let (instances, errorInstances) = try getInstanceList()
        self.instances = instances
        self.errorInstances = errorInstances
    }
    
    /// 异步加载该仓库中的所有实例。
    /// 只会在读取目录失败时抛出错误。
    public func loadAsync() async throws {
        let (instances, errorInstances) = try getInstanceList()
        await MainActor.run {
            self.instances = instances
            self.errorInstances = errorInstances
        }
    }
    
    /// 从仓库中加载实例。
    /// - Parameter id: 实例的 ID。
    /// - Returns: 实例对象。
    public func instance(id: String, version: MinecraftVersion? = nil) throws -> MinecraftInstance {
        return try .load(from: versionsURL.appending(path: id))
    }
    
    /// 判断仓库中是否存在带有指定 id 的实例。
    /// - Parameter id: 指定 id。
    /// - Returns: 一个 `Bool`，表示是否存在。
    public func contains(_ id: String) -> Bool {
        return FileManager.default.fileExists(atPath: versionsURL.appending(path: id).path)
    }
    
    /// 检查实例名是否合法。
    /// - Parameters:
    ///   - name: 待检查的实例名。
    ///   - trim: 是否删除首尾空白字符。
    /// - Returns: 经过 `trimmingCharacters(in: .whitespacesAndNewlines)` 处理后的实例名。
    /// - Throws: 如果非法，抛出 `NameCheckError`。
    public func checkInstanceName(_ name: String, trim: Bool = true) throws -> String {
        let trimmed: String = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trim && name != trimmed {
            throw NameCheckError.hasWhitespaceEdges
        }
        if trimmed.isEmpty {
            throw NameCheckError.empty
        }
        
        let invalidCharacters: [Character] = [
            ":", ";", "/", "\\"
        ]
        if invalidCharacters.contains(where: trimmed.contains(_:)) {
            throw NameCheckError.containsInvalidCharacter
        }
        
        if trimmed.starts(with: ".") {
            throw NameCheckError.startsWithDot
        }
        
        if self.contains(trimmed) {
            throw NameCheckError.alreadyExists
        }
        return trimmed
    }
    
    public enum NameCheckError: LocalizedError {
        case empty
        case hasWhitespaceEdges
        case containsInvalidCharacter
        case startsWithDot
        case alreadyExists
        
        public var errorDescription: String? {
            switch self {
            case .empty:
                "实例名不能为空。"
            case .hasWhitespaceEdges:
                "实例名首尾不能包含空白字符。"
            case .containsInvalidCharacter:
                "实例名中不能包含非法字符（如换行、冒号等）。"
            case .startsWithDot:
                "实例名不能以 . 开头。"
            case .alreadyExists:
                "该名称已被占用！"
            }
        }
    }
    
    
    private func getInstanceList() throws -> ([MinecraftInstance], [ErrorInstance]) {
        try createDirectories()
        var instances: [MinecraftInstance] = []
        var errorInstances: [ErrorInstance] = []
        let contents: [URL] = try FileManager.default.contentsOfDirectory(at: versionsURL, includingPropertiesForKeys: [.isDirectoryKey])
        for content in contents where try content.resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false {
            let instance: MinecraftInstance
            do {
                log("正在加载实例 \(content.lastPathComponent)")
                instance = try MinecraftInstance.load(from: content)
            } catch MinecraftError.incomplete {
                log("实例未完成安装，正在尝试自动删除")
                do {
                    try FileManager.default.removeItem(at: content)
                } catch {
                    err("删除失败：\(error.localizedDescription)")
                    errorInstances.append(.init(name: content.lastPathComponent, message: "该实例未完成安装，且自动删除失败。"))
                }
                continue
            } catch {
                err("加载实例失败：\(error.localizedDescription)")
                errorInstances.append(.init(name: content.lastPathComponent, message: error.localizedDescription))
                continue
            }
            instances.append(instance)
        }
        return (instances, errorInstances)
    }
    
    public static func == (lhs: MinecraftRepository, rhs: MinecraftRepository) -> Bool {
        return lhs.url == rhs.url
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(name)
    }
    
    public enum CodingKeys: String, CodingKey { case name, url, instances }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.url = try container.decode(URL.self, forKey: .url)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.url, forKey: .url)
    }
    
    public struct ErrorInstance {
        public let name: String
        public let message: String
    }
}
