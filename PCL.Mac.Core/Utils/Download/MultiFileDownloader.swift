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
    
    public init(items: [DownloadItem], concurrentLimit: Int, replaceMethod: ReplaceMethod, progressHandler: (@MainActor (Double) -> Void)? = nil) {
        self.items = items
        self.concurrentLimit = concurrentLimit
        self.replaceMethod = replaceMethod
        self.progressHandler = progressHandler
    }
    
    public func start() async throws {
        let total: Int = items.count
        var tickerTask: Task<Void, Error>? = nil
        if let progressHandler {
            tickerTask = Task {
                while true {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                    await MainActor.run {
                        progressHandler(Array(self.progress.values).reduce(0, +))
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
        progress[uuid] = 0
        try await SingleFileDownloader.download(item, replaceMethod: replaceMethod) { progress in
            self.progress[uuid]! += progress / Double(self.items.count)
        }
    }
}
