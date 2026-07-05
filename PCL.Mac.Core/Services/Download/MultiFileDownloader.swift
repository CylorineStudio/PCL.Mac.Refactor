//
//  MultiFileDownloader.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/11/24.
//

import Foundation

public class _MultiFileDownloader {
    private var downloadSourceManager: DownloadSourceManager
    private let items: [DownloadItem]
    private let concurrentLimit: Int
    private let replaceMethod: ReplaceMethod
    private let maxRetryCount: Int
    private let progressHandler: (@MainActor (Double) -> Void)?
    private var progress: [UUID: Double] = [:]
    
    public init(
        downloadSourceManager: DownloadSourceManager = .shared,
        items: [DownloadItem],
        concurrentLimit: Int,
        replaceMethod: ReplaceMethod,
        maxRetryCount: Int = 2,
        progressHandler: (@MainActor (Double) -> Void)? = nil
    ) {
        self.downloadSourceManager = downloadSourceManager
        
        self.items = items
        self.concurrentLimit = concurrentLimit
        self.replaceMethod = replaceMethod
        self.maxRetryCount = maxRetryCount
        self.progressHandler = progressHandler
    }
    
    public func start() async throws {
        var items: [DownloadItem] = []
        if replaceMethod == .skip {
            for item in self.items {
                let path: String = item.destination.path
                if FileManager.default.fileExists(atPath: path) {
                    if try FileUtils.check(item) == true {
                        continue
                    } else {
                        try FileManager.default.removeItem(at: item.destination)
                    }
                }
                items.append(item)
            }
        } else {
            items = self.items
        }
        let dedupedItems = Array(Set(items))
        let total = dedupedItems.count
        let skipped = self.items.count - dedupedItems.count
        var tickerTask: Task<Void, Error>? = nil
        if let progressHandler {
            tickerTask = Task {
                while true {
                    try await Task.sleep(seconds: 0.1)
                    await MainActor.run {
                        progressHandler((Array(progress.values).reduce(0, +) + Double(skipped)) / Double(self.items.count))
                    }
                }
            }
        }
        defer { tickerTask?.cancel() }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            let semaphore = AsyncSemaphore(value: downloadSourceManager.concurrentLimit)
            
            for item in dedupedItems {
                if Task.isCancelled { break }
                await semaphore.wait()
                group.addTask {
                    defer { Task { await semaphore.signal() } }
                    try await self.download(item)
                }
            }
            
            try await group.waitForAll()
        }
    }
    
    private func download(_ item: DownloadItem) async throws {
        let uuid = UUID()
        await MainActor.run {
            progress[uuid] = 0
        }
        try await _SingleFileDownloader.download(item, replaceMethod: replaceMethod, maxRetryCount: maxRetryCount) { progress in
            self.progress[uuid] = progress
        }
    }
}
