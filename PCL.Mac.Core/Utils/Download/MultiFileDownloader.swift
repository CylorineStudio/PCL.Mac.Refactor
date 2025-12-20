//
//  MultiFileDownloader.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/24.
//

import Foundation

public class MultiFileDownloader {
    private let items: [DownloadItem]
    private let concurrentLimit: Int
    private let replaceMethod: ReplaceMethod
    private let progressHandler: (@MainActor (Double) -> Void)?
    private var progress: [UUID: Double] = [:]
    
    public init(items: [DownloadItem],
                concurrentLimit: Int,
                replaceMethod: ReplaceMethod,
                progressHandler: (@MainActor (Double) -> Void)? = nil) {
        self.items = items
        self.concurrentLimit = concurrentLimit
        self.replaceMethod = replaceMethod
        self.progressHandler = progressHandler
    }
    
    public func start() async throws {
        var items: [DownloadItem] = []
        if replaceMethod == .skip {
            for item in self.items {
                let path: String = item.destination.path
                if FileManager.default.fileExists(atPath: path) {
                    guard let sha1 = item.sha1 else { continue }
                    if try FileUtils.sha1(of: item.destination) == sha1 {
                        continue
                    }
                    try FileManager.default.removeItem(at: item.destination)
                }
                items.append(item)
            }
        } else {
            items = self.items
        }
        let total: Int = items.count
        let skipped: Int = self.items.count - items.count
        var tickerTask: Task<Void, Error>? = nil
        if let progressHandler {
            tickerTask = Task {
                while true {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                    await MainActor.run {
                        progressHandler((Array(progress.values).reduce(0, +) + Double(skipped)) / Double(self.items.count))
                    }
                }
            }
        }
        defer { tickerTask?.cancel() }
        
        var nextIndex: Int = 0
        try await withThrowingTaskGroup(of: Void.self) { group in
            let initial = min(concurrentLimit, total)
            while nextIndex < initial {
                let item = items[nextIndex]
                group.addTask {
                    try await self.download(item)
                }
                nextIndex += 1
            }
            
            while let _ = try await group.next() {
                if nextIndex < total {
                    let item = items[nextIndex]
                    group.addTask {
                        try await self.download(item)
                    }
                    nextIndex += 1
                }
            }
        }
    }
    
    private func download(_ item: DownloadItem) async throws {
        let uuid: UUID = .init()
        await MainActor.run {
            progress[uuid] = 0
        }
        try await SingleFileDownloader.download(item, replaceMethod: replaceMethod) { progress in
            self.progress[uuid] = progress
        }
    }
}
