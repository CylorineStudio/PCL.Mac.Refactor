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
    
    public init(items: [DownloadItem], concurrentLimit: Int, replaceMethod: ReplaceMethod) {
        self.items = items
        self.concurrentLimit = concurrentLimit
        self.replaceMethod = replaceMethod
    }
    
    public func start() async throws {
        let total: Int = items.count
        
        var nextIndex = 0
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
        try await SingleFileDownloader.download(item, replaceMethod: replaceMethod)
    }
}
