//
//  DownloadSpeedManager.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/11/24.
//

import Foundation

public class DownloadSpeedManager {
    public static let shared: DownloadSpeedManager = .init()
    
    private var totalBytes: Int64 = 0
    private var lastResetTime: TimeInterval = Date().timeIntervalSince1970
    
    private init() {
    }
    
    public func addBytes(_ bytes: Int64) {
        self.totalBytes += bytes
    }
    
    public func reset() {
        self.totalBytes = 0
        self.lastResetTime = Date().timeIntervalSince1970
    }
    
    public func currentSpeed() -> Double {
        let now: TimeInterval = Date().timeIntervalSince1970
        let deltaTime: TimeInterval = now - lastResetTime
        guard deltaTime > 0 else {
            return 0.0
        }
        return Double(totalBytes) / deltaTime
    }
}
