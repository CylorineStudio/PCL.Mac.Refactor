//
//  MinecraftLauncher.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/26.
//

import Foundation

public class MinecraftLauncher {
    private static let gameLogQueue: DispatchQueue = .init(label: "PCL.Mac.GameLog")
    public let options: LaunchOptions
    public let logURL: URL
    private let manifest: ClientManifest
    private let runningDirectory: URL
    private let librariesURL: URL
    private var values: [String: String]
    
    public init(options: LaunchOptions) {
        self.manifest = options.manifest
        self.runningDirectory = options.runningDirectory
        self.librariesURL = options.repository.librariesURL
        self.options = options
        self.logURL = URLConstants.tempURL.appending(path: "game-log-\(UUID().uuidString.lowercased()).log")
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
        arguments.append(contentsOf: manifest.jvmArguments.flatMap { $0.rules.allSatisfy { $0.test(with: options) } ? $0.value : [] })
        arguments.append(manifest.mainClass)
        arguments.append(contentsOf: manifest.gameArguments.flatMap { $0.rules.allSatisfy { $0.test(with: options) } ? $0.value : [] })
        arguments = arguments.map(replaceWithValue(_:))
        process.arguments = arguments
        
        // accessToken 打码
        // arguments 不会再被使用了，可以直接修改
        if let accessTokenIndex: Int = arguments.firstIndex(of: "--accessToken"),
           accessTokenIndex + 1 < arguments.count {
            arguments[accessTokenIndex + 1] = "🥚"
        }
        
        let pipe: Pipe = .init()
        process.standardOutput = pipe
        process.standardError = pipe
        
        log("正在使用以下参数启动 Minecraft：\(arguments)")
        try process.run()
        Self.gameLogQueue.async {
            FileManager.default.createFile(atPath: self.logURL.path, contents: nil)
            let handle: FileHandle?
            do {
                handle = try .init(forWritingTo: self.logURL)
            } catch {
                err("开启日志 FileHandle 失败：\(error.localizedDescription)")
                handle = nil
            }
            defer { try? handle?.close() }
            
            while process.isRunning {
                let data: Data = pipe.fileHandleForReading.availableData
                if data.isEmpty { break }
                try? handle?.write(contentsOf: data)
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
