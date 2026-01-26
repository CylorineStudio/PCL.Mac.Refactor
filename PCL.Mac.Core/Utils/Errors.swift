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
    case invalidMemory
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

public struct SimpleError: LocalizedError {
    private let reason: String
    
    public init(_ reason: String) {
        self.reason = reason
    }
    
    public var errorDescription: String? { reason }
}
