//
//  ConcurrentProgressHandler.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/2/16.
//

import Foundation

@MainActor
public class ConcurrentProgressHandler {
    private let totalHandler: @MainActor (Double) -> Void
    private var progressMap: [UUID: Progress] = [:]
    private var calculateTask: Task<Void, Error>?
    
    public init(totalHandler: @MainActor @escaping (Double) -> Void) {
        self.totalHandler = totalHandler
    }
    
    public init(initial: Double, totalHandler: @MainActor @escaping (Double) -> Void) {
        self.totalHandler = totalHandler
        self.progressMap[UUID()] = .init(multiplier: 1.0, currentProgress: initial)
    }
    
    deinit {
        calculateTask?.cancel()
        calculateTask = nil
    }
    
    /// 创建一个新的进度处理器。
    /// - Parameter multiplier: 该处理器的倍率。
    public func handler(withMultiplier multiplier: Double) -> (@MainActor (Double) -> Void) {
        let id = UUID()
        progressMap[id] = .init(multiplier: multiplier)
        let handler: (@MainActor (Double) -> Void) = { [weak self] progress in
            self?.progressMap[id]?.currentProgress = progress
        }
        return handler
    }
    
    /// 开始计算并同步进度。
    /// - Parameter interval: 计算间隔，默认为 0.1s。
    public func startCalculate(interval: Double = 0.1) {
        if calculateTask != nil { return }
        calculateTask = Task.detached { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.totalHandler(await self.calculateProgress())
                try await Task.sleep(seconds: interval)
            }
        }
    }
    
    /// 停止计算并最后一次同步进度。
    public func stopCalculate() {
        calculateTask?.cancel()
        calculateTask = nil
        totalHandler(1)
    }
    
    private func calculateProgress() -> Double {
        min(max(progressMap.values.reduce(0) { $0 + $1.currentProgress * $1.multiplier }, 0), 1)
    }
    
    private class Progress {
        public let multiplier: Double
        public var currentProgress: Double
        
        init(multiplier: Double, currentProgress: Double = 0) {
            self.multiplier = multiplier
            self.currentProgress = currentProgress
        }
    }
}
