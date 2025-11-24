//
//  SingleFileDownloader.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/22.
//

import Foundation

/// 单文件下载器。
public enum SingleFileDownloader {
    public static func download(_ item: DownloadItem, replaceMethod: ReplaceMethod) async throws {
        try await download(url: item.url, destination: item.destination, sha1: item.sha1, replaceMethod: replaceMethod)
    }
    
    public static func download(url: URL, destination: URL, sha1: String?, replaceMethod: ReplaceMethod) async throws {
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
        }
        
        var request: URLRequest = .init(url: url)
        request.httpMethod = "GET"
        
        let (byteStream, response) = try await URLSession.shared.bytes(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw DownloadError.badResponse
        }
        if !(200..<300).contains(response.statusCode) {
            throw DownloadError.badStatusCode(code: response.statusCode)
        }
        
        var buffer: [UInt8] = []
        buffer.reserveCapacity(64 * 1024)
        let tempFile: URL = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        FileManager.default.createFile(atPath: tempFile.path, contents: nil)
        let handle: FileHandle = try FileHandle(forWritingTo: tempFile)
        defer {
            try? handle.close()
            try? FileManager.default.removeItem(at: tempFile)
        }
        
        for try await byte in byteStream {
            buffer.append(byte)
            if buffer.count >= 64 * 1024 {
                handle.write(Data(buffer))
                buffer.removeAll(keepingCapacity: true)
            }
        }
        handle.write(Data(buffer))
        
        // 验证 SHA-1
        if let sha1 {
            guard try FileUtils.getSHA1(tempFile) == sha1 else {
                throw DownloadError.checksumMismatch
            }
        }
        // 保证 destination 位置不存在文件
        try FileManager.default.moveItem(at: tempFile, to: destination)
    }
}
