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

public struct SimpleError: LocalizedError {
    private let reason: String
    
    public init(_ reason: String) {
        self.reason = reason
    }
    
    public var errorDescription: String? { reason }
}
