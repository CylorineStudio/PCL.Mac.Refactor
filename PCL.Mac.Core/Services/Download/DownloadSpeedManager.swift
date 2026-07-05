//
//  DownloadSpeedManager.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/11/24.
//

import Foundation

public class DownloadSpeedManager: ObservableObject {
    public static let shared: DownloadSpeedManager = .init()
    
    @Published public private(set) var currentSpeed: Int64 = 0
    private var tickerTask: Task<Void, Error>?
    @MainActor private var bytes: Int64 = 0
    
    private init() {
        self.tickerTask = .init(priority: .background) {
            while !Task.isCancelled {
                try await Task.sleep(seconds: 1)
                await updateSpeed()
            }
        }
    }
    
    @MainActor
    private func updateSpeed() {
        currentSpeed = bytes
        bytes = 0
    }
    
    @MainActor
    public func addBytes(_ bytes: Int64) {
        self.bytes += bytes
    }
}
