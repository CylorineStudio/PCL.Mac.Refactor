//
//  MinecraftLauncher.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/26.
//

import Foundation

public class MinecraftLauncher {
    private let manifest: ClientManifest
    private let runningDirectory: URL
    private let librariesURL: URL
    private let options: LaunchOptions
    private var values: [String: String]
    
    public init(options: LaunchOptions) {
        self.manifest = options.manifest
        self.runningDirectory = options.runningDirectory
        self.librariesURL = options.runningDirectory.deletingLastPathComponent().deletingLastPathComponent().appending(path: "libraries") // TODO
        self.options = options
        // test only
        self.values = [
            "auth_player_name": "Test",
            "version_name": manifest.id,
            "game_directory": runningDirectory.path,
            "assets_root": librariesURL.deletingLastPathComponent().appending(path: "assets").path,
            "assets_index_name": manifest.assetIndex.id,
            "auth_uuid": "00000000000000000000000000000000",
            "auth_access_token": "00000000000000000000000000000000",
            "user_type": "msa",
            "version_type": "PCL.Mac",
            "user_properties": "\"{}\""
        ]
    }
    
    /// 启动 Minecraft。
    /// - Returns: 进程退出代码。
    public func launch(_ completion: ((Process) -> Void)? = nil) throws -> Int32 {
        values["classpath"] = buildClasspath()
        let process: Process = .init()
        process.executableURL = options.javaURL!
        process.currentDirectoryURL = runningDirectory
        var arguments: [String] = []
        arguments.append(contentsOf: manifest.jvmArguments.flatMap { $0.rules.allSatisfy { $0.test() } ? $0.value : [] })
        arguments.append(manifest.mainClass)
        arguments.append(contentsOf: manifest.gameArguments.flatMap { $0.rules.allSatisfy { $0.test() } ? $0.value : [] })
        arguments = arguments.map(replaceWithValue(_:))
        process.arguments = arguments
        log("正在使用以下参数启动 Minecraft：\(arguments)")
        try process.run()
        completion?(process)
        process.waitUntilExit()
        return process.terminationStatus
    }
    
    private func buildClasspath() -> String {
        var urls: [URL] = []
        for library in manifest.libraries {
            if library.isRulesSatisfied, let artifact = library.artifact {
                urls.append(librariesURL.appending(path: artifact.path))
            }
        }
        urls.append(runningDirectory.appending(path: "\(runningDirectory.lastPathComponent).jar"))
        return urls.map(\.path).joined(separator: ":")
    }
    
    private func replaceWithValue(_ string: String) -> String {
        var s: String = string
        for key in values.keys {
            s.replace("${\(key)}", with: values[key]!)
        }
        return s
    }
}
