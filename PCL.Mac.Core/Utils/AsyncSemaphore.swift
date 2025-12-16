//
//  AsyncSemaphore.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/16.
//

import Foundation

public actor AsyncSemaphore {
    private let maxCount: Int
    private var currentCount: Int
    private var waitQueue: [CheckedContinuation<Void, Never>] = []
    
    public init(value: Int) {
        self.maxCount = value
        self.currentCount = value
    }
    
    public func wait() async {
        if currentCount > 0 {
            currentCount -= 1
        } else {
            await withCheckedContinuation { continuation in
                waitQueue.append(continuation)
            }
        }
    }
    
    public func signal() {
        if !waitQueue.isEmpty {
            let continuation = waitQueue.removeFirst()
            continuation.resume()
        } else if currentCount < maxCount {
            currentCount += 1
        }
    }
}
