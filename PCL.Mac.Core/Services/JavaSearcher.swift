//
//  JavaSearcher.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/8.
//

import Foundation

public enum JavaSearcher {
    /// 内部可能存在 Java 目录（如 `zulu-21.jdk`）的目录
    private static let javaDirectories: [URL] = [
        URL(fileURLWithPath: "/Library/Java/JavaVirtualMachines"),
        FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library/Java/JavaVirtualMachines")
    ]
    
    /// 搜索当前环境中安装的 Java（不包含 `/usr/bin/java`）。
    /// - Returns: 当前环境中安装的 Java 列表。
    public static func search() throws -> [JavaRuntime] {
        var runtimes: [JavaRuntime] = []
        let bundles: [URL] = try findJavaBundles()
        for bundle in bundles {
            let homeDirectory: URL = bundle.appending(path: "Contents/Home")
            do {
                let runtime: JavaRuntime = try load(from: homeDirectory)
                runtimes.append(runtime)
            } catch {
                err("加载 Java 失败：\(error.localizedDescription)")
                debug("homeDirectory：\(homeDirectory.path)")
            }
        }
        return runtimes
    }
    
    /// 加载磁盘上的 `JavaRuntime`。
    ///
    /// - Parameter url: 运行时的 `URL`，包含 `Home` 目录即可。
    public static func load(from url: URL) throws -> JavaRuntime {
        var url: URL = url
        while url.path != "/" {
            if url.lastPathComponent == "Home" && url.deletingLastPathComponent().lastPathComponent == "Contents" {
                break
            }
            url = url.deletingLastPathComponent()
        }
        if url.path == "/" {
            throw JavaError.invalidURL
        }
        let homeDirectory: URL = url
        // 解析 release 文件
        guard let releaseData: Data = FileManager.default.contents(atPath: homeDirectory.appending(path: "release").path),
              let releaseContent: String = .init(data: releaseData, encoding: .utf8) else {
            throw JavaError.failedToParseReleaseFile
        }
        let release: [String: String] = parseProperties(releaseContent)
        guard let javaVersion = release["JAVA_VERSION"] else {
            throw JavaError.failedToParseReleaseFile
        }
        guard let versionMajor: Int = parseVersionNumber(javaVersion) else {
            throw JavaError.failedToParseVersionNumber(version: javaVersion)
        }
        let implementor: String = release["IMPLEMENTOR"] ?? "Unknown"
        
        // Java 类型判断
        var type: JavaRuntime.JavaType?
        var executableURL: URL?
        var architecture: Architecture?
        for (javaType, path) in [
            (JavaRuntime.JavaType.jdk, "bin/java"),
            (JavaRuntime.JavaType.jre, "jre/bin/java")
        ] {
            let url: URL = homeDirectory.appending(path: path)
            let arch: Architecture = .architecture(of: url)
            if arch != .unknown {
                type = javaType
                executableURL = url
                architecture = arch
                break
            }
        }
        guard let type, let executableURL, let architecture else {
            throw JavaError.missingExecutableFile
        }
        return JavaRuntime(
            version: javaVersion,
            versionNumber: versionMajor,
            type: type,
            architecture: architecture,
            implementor: implementor,
            executableURL: executableURL
        )
    }
    
    private static func parseProperties(_ fileContent: String) -> [String: String] {
        var result: [String: String] = [:]
        for rawLine in fileContent.split(separator: "\n") {
            let line: String = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            let parts: [String] = line.components(separatedBy: "=")
            guard parts.count >= 2 else { continue }
            let key: String = parts[0].trimmingCharacters(in: .whitespaces)
            let value: String = parts[1...].joined(separator: "=").trimmingCharacters(in: .whitespaces.union(["\""]))
            result[key] = value
        }
        return result
    }
    
    private static func parseVersionNumber(_ version: String) -> Int? {
        let components: [String] = version.split(separator: ".").map(String.init)
        if components.count > 1 {
            if components[0] == "1" {
                return Int(components[1])
            } else {
                return Int(components[0])
            }
        }
        return nil
    }
    
    private static func findJavaBundles() throws -> [URL] {
        var bundleDirectories: [URL] = []
        
        for directory in javaDirectories {
            bundleDirectories.append(contentsOf: try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil))
        }
        // Homebrew
        let homebrewDirectories: [URL] = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: "/opt/homebrew/opt"), includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.starts(with: "openjdk@") }
        for directory in homebrewDirectories {
            bundleDirectories.append(directory.appending(path: "libexec").appending(path: "openjdk.jdk"))
        }
        return bundleDirectories.filter { FileManager.default.fileExists(atPath: $0.appending(path: "Contents/Home/release").path) }
    }
}
