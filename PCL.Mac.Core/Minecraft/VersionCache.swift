//
//  VersionCache.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/12.
//

import Foundation

public class VersionCache {
    private let cacheURL: URL
    private var cache: Model
    
    public init(from cacheURL: URL) throws {
        self.cacheURL = cacheURL
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            self.cache = .init()
            log("成功初始化版本缓存列表")
            try save()
            return
        }
        self.cache = try JSONDecoder.shared.decode(Model.self, from: try .init(contentsOf: cacheURL))
    }
    
    public func version(of instance: MinecraftInstance) -> MinecraftVersion? {
        return version(of: instance.manifestURL)
    }
    
    public func version(of manifestURL: URL) -> MinecraftVersion? {
        let sha1: String
        do {
            sha1 = try FileUtils.sha1(of: manifestURL)
        } catch {
            err("获取文件 SHA-1 失败：\(error.localizedDescription)")
            return nil
        }
        if let entry = cache.entries[sha1] {
            // 缓存命中，更新 time
            entry.time = Date()
            return MinecraftVersion(entry.version)
        }
        return nil
    }
    
    public func add(version: MinecraftVersion, for instance: MinecraftInstance) {
        add(version: version.id, for: instance)
    }
    
    public func add(version: String, for instance: MinecraftInstance) {
        let sha1: String
        do {
            sha1 = try FileUtils.sha1(of: instance.manifestURL)
        } catch {
            err("获取文件 SHA-1 失败：\(error.localizedDescription)")
            return
        }
        cache.entries[sha1] = .init(version: version, time: Date())
    }
    
    public func save() throws {
        if !FileManager.default.fileExists(atPath: cacheURL.path) {
            try FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        }
        try JSONEncoder.shared.encode(cache).write(to: cacheURL)
    }
    
    fileprivate struct Model: Codable {
        public var entries: [String: Entry]
        
        public init() {
            self.entries = [:]
        }
        
        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.entries = try container.decode([String: Entry].self)
        }
        
        func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(self.entries)
        }
        
        fileprivate class Entry: Codable {
            public let version: String
            public var time: Date
            
            public init(version: String, time: Date) {
                self.version = version
                self.time = time
            }
        }
    }
}
