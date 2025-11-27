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
    case badResponse
    case badStatusCode(code: Int)
}

public enum LaunchError: Error {
    case missingJava
    case missingRunningDirectory
    case missingManifest
    case missingAccount
    case invalidMemory
}

public struct SimpleError: LocalizedError {
    private let reason: String
    
    public init(_ reason: String) {
        self.reason = reason
    }
    
    public var errorDescription: String? { reason }
}
