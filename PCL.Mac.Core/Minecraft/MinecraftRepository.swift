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
    @Published public var currentInstanceId: UUID?
    public let url: URL
    
    @Published public var instances: [MinecraftInstance_]?
    @Published public var errorInstances: [ErrorInstance]?
    public var currentInstance: MinecraftInstance_? {
        get {
            guard let currentInstanceId else { return nil }
            return instances?.first(where: { $0.id == currentInstanceId })
        }
        set { currentInstanceId = newValue?.id }
    }
    
    public private(set) lazy var assetsDirectory: URL = url.appending(path: "assets")
    public private(set) lazy var librariesDirectory: URL = url.appending(path: "libraries")
    public private(set) lazy var versionsDirectory: URL = url.appending(path: "versions")
    
    public init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
    
    /// 创建必要目录。
    public func createDirectories() throws {
        let fileManager: FileManager = .default
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: assetsDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: librariesDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: versionsDirectory, withIntermediateDirectories: true)
    }
    
    /// 加载该仓库中的所有实例。
    /// 只会在读取目录失败时抛出错误。
    public func load() async throws {
        let result = try await loadInstances()
        await MainActor.run {
            self.instances = result.instances
            self.errorInstances = result.errorInstances
        }
    }
    
    /// 从仓库中加载实例。
    /// - Parameter id: 实例的 ID。
    /// - Returns: 实例对象。
    public func instance(id: String, version: MinecraftVersion? = nil) throws -> MinecraftInstance {
        return try .load(from: versionsDirectory.appending(path: id))
    }
    
    /// 判断仓库中是否存在带有指定 id 的实例。
    /// - Parameter id: 指定 id。
    /// - Returns: 一个 `Bool`，表示是否存在。
    public func contains(_ id: String) -> Bool {
        return FileManager.default.fileExists(atPath: versionsDirectory.appending(path: id).path)
    }
    
    /// 检查实例名是否合法。
    /// - Parameters:
    ///   - name: 待检查的实例名。
    ///   - trim: 是否删除首尾空白字符。
    /// - Returns: 经过 `trimmingCharacters(in: .whitespacesAndNewlines)` 处理后的实例名。
    /// - Throws: 如果非法，抛出 `NameCheckError`。
    public func checkInstanceName(_ name: String, trim: Bool = true) throws(NameCheckError) -> String {
        let trimmed: String = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trim && name != trimmed {
            throw .hasWhitespaceEdges
        }
        if trimmed.isEmpty {
            throw .empty
        }
        
        let invalidCharacters: [Character] = [
            ":", ";", "/", "\\"
        ]
        if invalidCharacters.contains(where: trimmed.contains(_:)) {
            throw .containsInvalidCharacter
        }
        
        if trimmed.starts(with: ".") {
            throw .startsWithDot
        }
        
        if self.contains(trimmed) {
            throw .alreadyExists
        }
        return trimmed
    }
    
    
    private func loadInstances() async throws -> LoadResult {
        guard FileManager.default.fileExists(atPath: versionsDirectory.path) else {
            return .empty
        }
        
        let instanceDirectories: [URL] = try FileManager.default.contentsOfDirectory(
            at: versionsDirectory,
            includingPropertiesForKeys: [.isDirectoryKey]
        ).filter { url in
            let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
            return resourceValues.isDirectory == true
        }
        
        return await withTaskGroup { group in
            for instanceDirectory in instanceDirectories {
                group.addTask {
                    return self.loadInstance(at: instanceDirectory)
                }
            }
            
            var instances: [MinecraftInstance_] = []
            var errorInstances: [ErrorInstance] = []
            
            for await result in group {
                switch result {
                case .success(let instance):
                    instances.append(instance)
                case .incomplete:
                    break
                case .failure(let errorInstance):
                    errorInstances.append(errorInstance)
                }
            }
            return .init(instances: instances, errorInstances: errorInstances)
        }
    }
    
    private func loadInstance(at url: URL) -> InstanceLoadResult {
        let name = url.lastPathComponent
        log("正在加载实例 \(name)")
        do {
            let instance = try MinecraftInstanceLoader.load(from: url)
            return .success(instance)
        } catch .incomplete {
            log("实例未完成安装，正在尝试自动删除")
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                err("删除失败：\(error.localizedDescription)")
                return .failure(name, message: "该实例未完成安装，且自动删除失败。")
            }
            return .incomplete
        } catch {
            err("加载实例失败：\(error.localizedDescription)")
            return .failure(name, message: error.localizedDescription)
        }
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.url = try container.decode(URL.self, forKey: .url)
        self.currentInstanceId = try container.decodeIfPresent(UUID.self, forKey: .currentInstanceId)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(url, forKey: .url)
        try container.encode(currentInstanceId, forKey: .currentInstanceId)
    }
    
    public static func == (lhs: MinecraftRepository, rhs: MinecraftRepository) -> Bool {
        return lhs.url == rhs.url
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(name)
    }
    
    public enum CodingKeys: String, CodingKey { case name, url, currentInstanceId }
    
    public struct LoadResult {
        public let instances: [MinecraftInstance_]
        public let errorInstances: [ErrorInstance]
        
        public static let empty: LoadResult = .init(instances: [], errorInstances: [])
    }
    
    private enum InstanceLoadResult {
        case success(MinecraftInstance_)
        case incomplete
        case failure(ErrorInstance)
        
        static func failure(_ name: String, message: String) -> InstanceLoadResult {
            return .failure(.init(name: name, message: message))
        }
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
}

public struct ErrorInstance {
    public let name: String
    public let message: String
}
