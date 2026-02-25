//
//  ToolboxViewModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/2/25.
//

import SwiftUI
import GameplayKit
import Core

class ToolboxViewModel: ObservableObject {
    @Published public var currentCaveMessage: String = "反复点击这里可以查看……（后面忘了）"
    @Published public var revealProgress: Double = 1
    public lazy var todayDate: String = {
        let formatter: DateFormatter = .init()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: .now)
    }()
    
    public lazy var todayLucky: Int = {
        let key: String = "\(NSUserName())\(todayDate))"
        var seed: UInt64 = 0
        for byte in key.utf8 {
            seed = seed &* 257 &+ UInt64(byte)
        }
        let rng: GKMersenneTwisterRandomSource = .init(seed: seed)
        return rng.nextInt(upperBound: 100) + 1
    }()
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
    
    /// 将今日人品值转换为在 UI 上显示的文本。
    /// - Parameter value: 今日人品值。
    /// - Returns: 处理后的文本。
    public func formatLucky(_ value: Int) -> String {
        // https://github.com/PCL-Community/PCL-CE/blob/0965ff4779c2c8946ed54338b7443534c57b120e/Plain%20Craft%20Launcher%202/Pages/PageTools/PageToolsTest.xaml.vb#L501-L513
        if value >= 100 {
            return "\(value)！\(value)！\(value)！\n隐藏主题 欧皇…… 不对，主题系统好像还没做……"
        } else if value >= 95 {
            return "\(value)！差一点就到100了呢…"
        } else if value >= 90 {
            return "\(value)！好评如潮！"
        } else if value >= 60 {
            return "\(value)！还行啦，还行啦。"
        } else if value >= 40 {
            return "\(value)…勉强还行吧…"
        } else if value >= 30 {
            return "\(value)…呜…"
        } else if value >= 10 {
            return "\(value)…不会吧！"
        } else {
            return "\(value)…（是百分制哦）"
        }
    }
}
