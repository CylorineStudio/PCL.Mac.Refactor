//
//  SingleFileDownloader.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/22.
//

import Foundation

/// 单文件下载器。
public enum SingleFileDownloader {
    public static let session: URLSession = .init(configuration: .default,
                                                  delegate: DownloadDelegate(),
                                                  delegateQueue: .main)
    
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
            if let sha1, try FileUtils.getSHA1(destination) != sha1 {
                try FileManager.default.removeItem(at: destination)
            } else {
                switch replaceMethod {
                case .replace:
                    try FileManager.default.removeItem(at: destination)
                case .skip:
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
        let (url, response) = try await session.download(for: request, delegate: nil)
        guard let response = response as? HTTPURLResponse else {
            throw URLError.badResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            throw DownloadError.badStatusCode(code: response.statusCode)
        }
        
        // 验证 SHA-1
        if let sha1 {
            guard try FileUtils.getSHA1(url) == sha1 else {
                try FileManager.default.removeItem(at: url)
                throw DownloadError.checksumMismatch
            }
        }
        try FileManager.default.moveItem(at: url, to: destination)
    }
}
