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
    
    public static func download(_ item: DownloadItem, replaceMethod: ReplaceMethod, maxRetryCount: Int = 2, progressHandler: (@MainActor (Double) -> Void)? = nil) async throws {
        try await download(url: item.url, destination: item.destination, checksums: item.checksums, executable: item.executable, replaceMethod: replaceMethod, maxRetryCount: maxRetryCount, progressHandler: progressHandler)
    }
    
    public static func download(
        url: URL,
        destination: URL,
        sha1: String?,
        executable: Bool = false,
        replaceMethod: ReplaceMethod,
        maxRetryCount: Int = 2,
        progressHandler: (@MainActor (Double) -> Void)? = nil
    ) async throws {
        try await download(
            url: url,
            destination: destination,
            checksums: sha1.map { ["sha1": $0] } ?? [:],
            executable: executable,
            replaceMethod: replaceMethod,
            maxRetryCount: maxRetryCount,
            progressHandler: progressHandler
        )
    }
    
    public static func download(
        url: URL,
        destination: URL,
        checksums: [String: String]?,
        executable: Bool = false,
        replaceMethod: ReplaceMethod,
        maxRetryCount: Int = 2,
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
        
        var retryCount: Int = 0
        while true {
            let task: URLSessionDownloadTask = session.downloadTask(with: request)
            do {
                try await withTaskCancellationHandler {
                    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                        DownloadDelegate.shared.register(task: task, destination: destination, continuation: continuation, progressHandler: progressHandler)
                        task.resume()
                    }
                } onCancel: {
                    task.cancel()
                }
                break
            } catch {
                if error.isCancellationError { throw CancellationError() }
                try? FileManager.default.removeItem(at: destination)
                guard retryCount < maxRetryCount else { throw error }
                retryCount += 1
                try await Task.sleep(seconds: Double(retryCount) * 0.5)
            }
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
