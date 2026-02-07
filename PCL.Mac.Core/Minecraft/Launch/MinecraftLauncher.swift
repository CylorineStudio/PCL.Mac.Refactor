//
//  MinecraftLauncher.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/26.
//

import Foundation

public class MinecraftLauncher {
    private static let gameLogQueue: DispatchQueue = .init(label: "PCL.Mac.GameLog")
    public private(set) var output: String = ""
    public let options: LaunchOptions
    private let manifest: ClientManifest
    private let runningDirectory: URL
    private let librariesURL: URL
    private var values: [String: String]
    
    public init(options: LaunchOptions) {
        self.manifest = options.manifest
        self.runningDirectory = options.runningDirectory
        self.librariesURL = options.repository.librariesURL
        self.options = options
        self.values = [
            "natives_directory": runningDirectory.appending(path: "natives").path,
            "launcher_name": "PCL.Mac",
            "launcher_version": Metadata.appVersion,
            "classpath_separator": ":",
            "library_directory": librariesURL.path,
            
            "auth_player_name": options.profile.name,
            "version_name": manifest.id,
            "game_directory": runningDirectory.path,
            "assets_root": librariesURL.deletingLastPathComponent().appending(path: "assets").path,
            "assets_index_name": manifest.assetIndex.id,
            "auth_uuid": UUIDUtils.string(of: options.profile.id, withHyphens: false),
            "auth_access_token": options.accessToken,
            "user_type": "msa",
            "version_type": "PCL.Mac",
            "user_properties": "\"{}\""
        ]
    }
    
    /// 启动 Minecraft。
    /// - Returns: 游戏进程。
    public func launch() throws -> Process {
        values["classpath"] = buildClasspath()
        let process: Process = .init()
        process.executableURL = options.javaRuntime.executableURL
        process.currentDirectoryURL = runningDirectory
        
        var arguments: [String] = []
        arguments.append(contentsOf: manifest.jvmArguments.flatMap { $0.rules.allSatisfy { $0.test() } ? $0.value : [] })
        arguments.append(manifest.mainClass)
        arguments.append(contentsOf: manifest.gameArguments.flatMap { $0.rules.allSatisfy { $0.test() } ? $0.value : [] })
        arguments = arguments.map(replaceWithValue(_:))
        process.arguments = arguments
        
        let pipe: Pipe = .init()
        process.standardOutput = pipe
        process.standardError = pipe
        
        log("正在使用以下参数启动 Minecraft：\(arguments)")
        try process.run()
        Self.gameLogQueue.async {
            while process.isRunning {
                let data: Data = pipe.fileHandleForReading.availableData
                if data.isEmpty { break }
                if let string: String = .init(data: data, encoding: .utf8) {
                    self.output += string
                }
            }
        }
        return process
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
            s = s.replacingOccurrences(of: "${\(key)}", with: values[key]!)
        }
        return s
    }
}
