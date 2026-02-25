//
//  ToolboxViewModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/2/25.
//

import SwiftUI
import Core

class ToolboxViewModel: ObservableObject {
    @Published public var currentCaveMessage: String = "反复点击这里可以查看……（后面忘了）"
    @Published public var revealProgress: Double = 1
    public var caveMessages: [String] = []
    public var lastRefresh: Date = .distantPast
    
    /// 刷新回声洞消息列表。
    public func fetchCaveMessages() async throws {
        caveMessages = ["正在加载消息列表……"]
        caveMessages = try await CLAPIClient.shared.getCaveMessages()
    }
    
    /// 将当前消息改为 `caveMessages` 里的随机一条消息。
    /// - Returns: `caveMessages` 中是否有元素可供显示。
    public func refreshCaveMessage() -> Bool {
        if Date.now.timeIntervalSince(lastRefresh) < 0.3 { return true }
        lastRefresh = .now
        guard let newMessage: String = caveMessages.randomElement() else {
            return false
        }
        currentCaveMessage = newMessage
        
        revealProgress = 0.1
        withAnimation(.linear(duration: Double(newMessage.count) * 0.02)) {
            revealProgress = 1.0
        }
        return true
    }
}
