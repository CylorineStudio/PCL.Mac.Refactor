//
//  SingleFileDownloader.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/11/22.
//

import Foundation

/// 单文件下载器。
public enum SingleFileDownloader {
    public static let session: URLSession = .init(configuration: .default, delegate: DownloadDelegate.shared, delegateQueue: DownloadDelegate.queue)
    
    public static func download(_ item: DownloadItem, replaceMethod: ReplaceMethod, progressHandler: (@MainActor (Double) -> Void)? = nil) async throws {
        try await download(url: item.url, destination: item.destination, checksums: item.checksums, executable: item.executable, replaceMethod: replaceMethod, progressHandler: progressHandler)
    }
    
    public static func download(
        url: URL,
        destination: URL,
        sha1: String?,
        executable: Bool = false,
        replaceMethod: ReplaceMethod,
        progressHandler: (@MainActor (Double) -> Void)? = nil
    ) async throws {
        try await download(
            url: url,
            destination: destination,
            checksums: sha1.map { ["sha1": $0] } ?? [:],
            replaceMethod: replaceMethod,
            progressHandler: progressHandler
        )
    }
    
    public static func download(
        url: URL,
        destination: URL,
        checksums: [String: String]?,
        executable: Bool = false,
        replaceMethod: ReplaceMethod,
        progressHandler: (@MainActor (Double) -> Void)? = nil
    ) async throws {
        // 文件已存在处理
        if FileManager.default.fileExists(atPath: destination.path) {
            if let checksums, try FileUtils.checkFile(at: destination, with: checksums) != true {
                try FileManager.default.removeItem(at: destination)
            } else {
                switch replaceMethod {
                case .replace:
                    try FileManager.default.removeItem(at: destination)
                case .skip:
                    await progressHandler?(1)
                    return
                case .throw:
                    throw DownloadError.fileExists
                }
            }
        } else {
            try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        }
        
        var request: URLRequest = .init(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("PCL-Mac/\(Metadata.appVersion)", forHTTPHeaderField: "User-Agent")
        
        let task: URLSessionDownloadTask = session.downloadTask(with: request)
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                DownloadDelegate.shared.register(task: task, destination: destination, continuation: continuation, progressHandler: progressHandler)
                task.resume()
            }
        } onCancel: {
            task.cancel()
        }
        
        // 验证 checksums
        if let checksums {
            guard try FileUtils.checkFile(at: destination, with: checksums) == true else {
                try FileManager.default.removeItem(at: destination)
                throw DownloadError.checksumMismatch
            }
        }
        if executable {
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destination.path)
        }
    }
}

