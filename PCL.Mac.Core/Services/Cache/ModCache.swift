//
//  ModCache.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/7.
//

import Foundation

public class ModCache {
    public static var shared: ModCache!
    
    private let cacheFileURL: URL
    private let iconCacheDirectory: URL
    private var cacheMap: [String: Mod]
    
    public init(cacheDirectory: URL) {
        self.cacheFileURL = cacheDirectory.appending(path: "mod_cache.json")
        self.iconCacheDirectory = cacheDirectory.appending(path: "resource_icon")
        
        if FileManager.default.fileExists(atPath: cacheFileURL.path) {
            do {
                let data = try Data(contentsOf: cacheFileURL)
                self.cacheMap = try JSONDecoder.shared.decode([String: Mod].self, from: data)
            } catch {
                err("缓存文件加载失败：\(error.localizedDescription)")
                try? FileManager.default.removeItem(at: cacheFileURL)
                self.cacheMap = [:]
            }
        } else {
            self.cacheMap = [:]
        }
    }
    
    public func mod(forHash hash: String) -> Mod? { cacheMap[hash] }
    
    public func store(_ mod: Mod, forHash hash: String) { cacheMap[hash] = mod }
    
    public func icon(forHash globalHash: String) throws -> Data? {
        let url = url(of: globalHash)
        if FileManager.default.fileExists(atPath: url.path) {
            return try Data(contentsOf: url)
        }
        return nil
    }
    
    public func store(_ iconData: Data, relativePath: String, jarHash: String) throws -> String {
        let globalHash = globalHash(of: relativePath, with: jarHash)
        let url = url(of: globalHash)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try iconData.write(to: url)
        return globalHash
    }
    
    public func save() throws {
        try FileManager.default.createDirectory(at: cacheFileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder.shared.encode(cacheMap)
        try data.write(to: cacheFileURL)
    }
    
    
    private func url(of globalHash: String) -> URL {
        return iconCacheDirectory.appending(path: "\(globalHash.prefix(2))/\(globalHash)")
    }
    
    private func globalHash(of path: String, with jarHash: String) -> String {
        return (jarHash + path).sha1
    }
}
