//
//  FileDownloader.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/7/4.
//

import Foundation

public class FileDownloader {
    public static let shared: FileDownloader = {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: DownloadDelegate.shared, delegateQueue: DownloadDelegate.queue)
        return .init(session: session)
    }()
    
    private let session: URLSession
    private let sourceManager: DownloadSourceManager
    private let maxRetryCount: Int = 3
    
    public init(session: URLSession, sourceManager: DownloadSourceManager = .shared) {
        self.session = session
        self.sourceManager = sourceManager
    }
    
    public func download(
        _ file: DownloadItem,
        progressHandler: (@MainActor (Double) -> Void)? = nil,
        checkDestination: Bool = true
    ) async throws {
        if checkDestination && FileManager.default.fileExists(atPath: file.destination.path) {
            if try FileUtils.check(file) {
                debug("文件 \(file.destination.lastPathComponent) 已存在且校验通过，跳过下载")
                await progressHandler?(1)
                return
            } else {
                warn("文件 \(file.destination.lastPathComponent) 已存在但校验未通过")
                try FileManager.default.removeItem(at: file.destination)
            }
        }
        
        try FileManager.default.createDirectory(at: file.destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        var retryCount = 0
        while true {
            await progressHandler?(0)
            
            let url = sourceManager.currentSource.replacing(file.url)
            var request = URLRequest(url: url)
            request.setValue("PCL-Mac/\(Metadata.appVersion)", forHTTPHeaderField: "User-Agent")
            
            do {
                log("正在下载 \(url) → \(file.destination)")
                let task = session.downloadTask(with: request)
                try await DownloadDelegate.shared.start(task, destination: file.destination, progressHandler: progressHandler)
                break
            } catch {
                try? FileManager.default.removeItem(at: file.destination)
                
                if error.isCancellationError {
                    throw error
                } else if let error = error as? DownloadError,
                          case let .badStatusCode(code) = error,
                          [400, 401, 403, 404, 405, 410, 414].contains(code) {
                    throw error
                }
                
                guard retryCount < maxRetryCount else { throw error }
                retryCount += 1
                warn("下载文件 \(url.lastPathComponent) 失败：\(error.localizedDescription)，正在重试（\(retryCount)/\(maxRetryCount)）")
                try await Task.sleep(seconds: Double(retryCount) * 0.5)
            }
        }
        
        if file.checksums != nil {
            guard try FileUtils.check(file) else {
                try FileManager.default.removeItem(at: file.destination)
                throw DownloadError.checksumMismatch
            }
        }
        if file.executable {
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: file.destination.path)
        }
    }
    
    public func download(
        files: [DownloadItem],
        progressHandler: (@MainActor (Double) -> Void)? = nil
    ) async throws {
        let total = files.count
        var skipped = 0
        
        var items: [DownloadItem] = []
        items.reserveCapacity(files.count)
        
        for file in files {
            if FileManager.default.fileExists(atPath: file.destination.path) {
                if try FileUtils.check(file) {
                    skipped += 1
                    continue
                }
                try FileManager.default.removeItem(at: file.destination)
            }
            items.append(file)
        }
        if items.isEmpty {
            await progressHandler?(1.0)
            return
        }
        
        let progressHandler = await ConcurrentProgressHandler(
            initial: Double(skipped) / Double(total),
            totalHandler: progressHandler ?? { _ in }
        )
        let multiplier = 1.0 / Double(total)
        await progressHandler.startCalculate()
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            let semaphore = AsyncSemaphore(value: sourceManager.concurrentLimit)
            
            for item in items {
                if Task.isCancelled { break }
                await semaphore.wait()
                group.addTask {
                    defer { Task { await semaphore.signal() } }
                    try await self.download(item, progressHandler: await progressHandler.handler(withMultiplier: multiplier), checkDestination: false)
                }
            }
            
            try await group.waitForAll()
        }
    }
    
    
    public func download(url: URL, destination: URL, sha1: String? = nil, progressHandler: (@MainActor (Double) -> Void)? = nil) async throws {
        try await download(.init(url: url, destination: destination, sha1: sha1), progressHandler: progressHandler)
    }
}
