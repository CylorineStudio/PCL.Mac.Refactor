//
//  MinecraftInstance.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/25.
//

import Foundation
import SwiftyJSON

/// Minecraft 实例的数据模型与业务逻辑。
public class MinecraftInstance {
    public let runningDirectory: URL
    public let version: MinecraftVersion
    public let manifest: ClientManifest
    public var name: String { runningDirectory.lastPathComponent }
    
    /// 根据运行目录、版本与客户端清单创建实例对象。
    /// 如果只需要从磁盘加载实例，请使用 `MinecraftInstance.load(from:)`。
    /// - Parameters:
    ///   - runningDirectory: 实例运行目录。
    ///   - version: 实例的 Minecraft 版本。
    ///   - manifest: 客户端清单。
    public init(runningDirectory: URL, version: MinecraftVersion, manifest: ClientManifest) {
        self.runningDirectory = runningDirectory
        self.version = version
        self.manifest = manifest
    }
    
    /// 从磁盘加载实例。
    /// 对于老版本（如 `1.8.9`），可能无法正确检测 Minecraft 版本，所以请在安装时调用 `MinecraftInstance.init` 而不是本函数。
    /// - Parameter runningDirectory: 实例运行目录。
    /// - Returns: 实例对象。
    public static func load(from runningDirectory: URL) throws -> MinecraftInstance {
        log("正在加载实例 \(runningDirectory.lastPathComponent)")
        // 加载客户端清单
        let manifestURL: URL = runningDirectory.appending(path: "\(runningDirectory.lastPathComponent).json")
        let manifest: ClientManifest = try JSONDecoder.shared.decode(ClientManifest.self, from: Data(contentsOf: manifestURL))
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
