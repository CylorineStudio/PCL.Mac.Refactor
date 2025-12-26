//
//  MinecraftDirectory.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/26.
//

import Foundation

/// Minecraft 目录（`.minecraft`）。
public class MinecraftDirectory: ObservableObject, Codable {
    @Published public var name: String
    @Published public var url: URL
    @Published public var instances: [Instance]?
    
    public lazy var assetsURL: URL = { url.appending(path: "assets") }()
    public lazy var librariesURL: URL = { url.appending(path: "libraries") }()
    public lazy var versionsURL: URL = { url.appending(path: "versions") }()
    
    public init(name: String, url: URL, instances: [Instance]? = nil) {
        self.name = name
        self.url = url
        self.instances = instances
    }
    
    /// 加载该目录中的所有实例。
    public func load() throws {
        var instances: [Instance] = []
        let contents: [URL] = try FileManager.default.contentsOfDirectory(at: versionsURL, includingPropertiesForKeys: [.isDirectoryKey])
        for content in contents where try content.resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false {
            guard let instance: MinecraftInstance = try? MinecraftInstance.load(from: content) else {
                continue
            }
            let model: Instance = .init(
                name: instance.name,
                version: instance.version
            )
            instances.append(model)
        }
        self.instances = instances
    }
    
    public enum CodingKeys: String, CodingKey { case name, url, instances }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.url = try container.decode(URL.self, forKey: .url)
        self.instances = try container.decode([Instance].self, forKey: .instances)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.url, forKey: .url)
        try container.encode(self.instances, forKey: .instances)
    }
    
    public struct Instance: Codable {
        public let name: String
        public let version: MinecraftVersion
    }
}
