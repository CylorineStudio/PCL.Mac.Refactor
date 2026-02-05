//
//  Errors.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/22.
//

import Foundation

public enum DownloadError: Error, Equatable {
    case fileExists
    case checksumMismatch
    case badStatusCode(code: Int)
    case unknownError
}

public enum LaunchError: Error {
    case missingJava
    case missingRunningDirectory
    case missingManifest
    case missingAccount
    case missingRepository
}

public enum URLError: Error {
    case invalidURL
    case invalidType
    case badResponse
}

public enum TaskError: Error, Equatable {
    case invalidOrdinal(value: Int)
    case unknownError
}

public enum MinecraftError: LocalizedError {
    case missingManifest
    case unknownManifestFormat
    
    public var errorDescription: String? {
        switch self {
        case .missingManifest:
            "未找到客户端清单文件。"
        case .unknownManifestFormat:
            "未知的客户端清单格式，可能是由外部安装的实例。"
        }
    }
}

public enum UUIDError: Error, Equatable {
    case invalidUUIDFormat
}

public enum JavaError: LocalizedError {
    case invalidURL
    case failedToParseReleaseFile
    case missingExecutableFile
    case failedToParseVersionNumber(version: String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            "无效的 Java URL。"
        case .failedToParseReleaseFile:
            "解析 release 文件失败。"
        case .missingExecutableFile:
            "未找到可执行文件。"
        case .failedToParseVersionNumber(let version):
            "解析版本号 \(version) 失败。"
        }
    }
}

public struct SimpleError: LocalizedError {
    private let reason: String
    
    public init(_ reason: String) {
        self.reason = reason
    }
    
    public var errorDescription: String? { reason }
}
