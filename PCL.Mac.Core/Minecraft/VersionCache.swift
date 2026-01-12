//
//  VersionCache.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/12.
//

import Foundation

public enum VersionCache {
    private static let cacheURL: URL = URLConstants.cacheURL.appending(path: "version_cache.json")
    private static var cache: Model?
    
    public static func load() throws {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            self.cache = .init()
            log("成功初始化版本缓存列表")
            try save()
            return
        }
        self.cache = try JSONDecoder.shared.decode(Model.self, from: try .init(contentsOf: cacheURL))
        
        var expireCount: Int = 0
        let date: Date = .now
        for (key, value) in cache!.entries {
            if date.timeIntervalSince(value.time) > 7 * 24 * 60 * 60 { // 7 天
                cache!.entries.removeValue(forKey: key)
                expireCount += 1
            }
        }
        if expireCount != 0 {
            log("移除了 \(expireCount) 条过期的缓存")
        }
    }
    
    public static func version(of instance: MinecraftInstance) -> MinecraftVersion? {
        return version(of: instance.manifestURL)
    }
    
    public static func version(of manifestURL: URL) -> MinecraftVersion? {
        guard let cache = cache else {
            warn("试图获取 \(manifestURL.path) 的缓存值，但缓存还未被加载")
            return nil
        }
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
    
    public static func add(version: MinecraftVersion, for instance: MinecraftInstance) {
        add(version: version.id, for: instance)
    }
    
    public static func add(version: String, for instance: MinecraftInstance) {
        add(version: version, for: instance.manifestURL)
    }
    
    public static func add(version: String, for manifestURL: URL) {
        guard let cache = cache else {
            warn("试图修改 \(manifestURL.path) 的缓存值，但缓存还未被加载")
            return
        }
        let sha1: String
        do {
            sha1 = try FileUtils.sha1(of: manifestURL)
        } catch {
            err("获取文件 SHA-1 失败：\(error.localizedDescription)")
            return
        }
        cache.entries[sha1] = .init(version: version, time: Date())
    }
    
    public static func save() throws {
        if !FileManager.default.fileExists(atPath: cacheURL.path) {
            try FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        }
        try JSONEncoder.shared.encode(cache).write(to: cacheURL)
    }
    
    fileprivate class Model: Codable {
        public var entries: [String: Entry]
        
        public init() {
            self.entries = [:]
        }
        
        required public init(from decoder: any Decoder) throws {
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
