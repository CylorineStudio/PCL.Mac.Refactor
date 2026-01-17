//
//  SingleFileDownloader.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/22.
//

import Foundation

/// 单文件下载器。
public enum SingleFileDownloader {
    public static let session: URLSession = .init(configuration: .default, delegate: DownloadDelegate.shared, delegateQueue: DownloadDelegate.queue)
    
    public static func download(_ item: DownloadItem, replaceMethod: ReplaceMethod, progressHandler: (@MainActor (Double) -> Void)? = nil) async throws {
        try await download(url: item.url, destination: item.destination, sha1: item.sha1, replaceMethod: replaceMethod, progressHandler: progressHandler)
    }
    
    public static func download(url: URL,
                                destination: URL,
                                sha1: String?,
                                replaceMethod: ReplaceMethod,
                                progressHandler: (@MainActor (Double) -> Void)? = nil) async throws {
        // 文件已存在处理
        if FileManager.default.fileExists(atPath: destination.path) {
            if let sha1, try FileUtils.sha1(of: destination) != sha1 {
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
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let task: URLSessionDownloadTask = session.downloadTask(with: request)
            DownloadDelegate.shared.register(task: task, destination: destination, continuation: continuation, progressHandler: progressHandler)
            task.resume()
        }
        
        // 验证 SHA-1
        if let sha1 {
            guard try FileUtils.sha1(of: destination) == sha1 else {
                try FileManager.default.removeItem(at: destination)
                throw DownloadError.checksumMismatch
            }
        }
    }
}

