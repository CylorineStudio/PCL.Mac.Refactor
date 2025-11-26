//
//  MinecraftInstance.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/25.
//

import Foundation
import SwiftyJSON

public class MinecraftInstance {
    public let runningDirectory: URL
    public let version: MinecraftVersion
    public let manifest: ClientManifest
    public var name: String { runningDirectory.lastPathComponent }
    
    public init(runningDirectory: URL, version: MinecraftVersion, manifest: ClientManifest) {
        self.runningDirectory = runningDirectory
        self.version = version
        self.manifest = manifest
    }
    
    public static func load(runningDirectory: URL) throws -> MinecraftInstance {
        log("正在加载实例 \(runningDirectory.lastPathComponent)")
        // 加载客户端清单
        let manifestURL: URL = runningDirectory.appending(path: "\(runningDirectory.lastPathComponent).json")
        let manifestJSON: JSON = try JSON(data: Data(contentsOf: manifestURL))
        let manifest: ClientManifest = .init(json: manifestJSON)
        // 获取版本
        let version: MinecraftVersion
        let jarURL: URL = runningDirectory.appending(path: "\(runningDirectory.lastPathComponent).jar")
        if FileManager.default.fileExists(atPath: jarURL.path),
           try ArchiveUtils.hasEntry(url: jarURL, path: "version.json") {
            let json: JSON = try JSON(data: ArchiveUtils.getEntry(url: jarURL, path: "version.json"))
            log("成功解析 version.json")
            version = .init(json["id"].stringValue)
        } else {
            warn("version.json 不存在，使用客户端清单中的 id")
            version = .init(manifest.id)
        }
        return .init(
            runningDirectory: runningDirectory,
            version: version,
            manifest: manifest
        )
    }
}
