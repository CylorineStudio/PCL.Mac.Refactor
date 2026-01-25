//
//  MessageBoxManager.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/20.
//

import Foundation
import Core

class MessageBoxManager: ObservableObject {
    public static let shared: MessageBoxManager = .init()
    @Published public private(set) var currentMessageBox: MessageBoxModel?
    private let defaultButton: MessageBoxModel.Button = .init(id: 0, label: "确认", type: .normal)
    private let semaphore: AsyncSemaphore = .init(value: 1)
    private var continuation: CheckedContinuation<MessageBoxResult, Never>?
    
    /// 弹出一个带有纯文本内容的提示框。
    /// - Parameters:
    ///   - title: 提示框标题。
    ///   - content: 文本内容。
    ///   - level: 提示框等级，控制了提示框的颜色。
    ///   - buttons: 按钮列表。
    /// - Returns: 被点击的按钮的 `id`。
    public func showText(title: String, content: String, level: MessageBoxModel.Level = .info, _ buttons: MessageBoxModel.Button...) async -> Int {
        let buttons: [MessageBoxModel.Button] = buttons.isEmpty ? [defaultButton] : buttons
        let result: MessageBoxResult = await show(title: title, content: .text(text: content), level: level, buttons: buttons)
        if case .button(let id) = result {
            return id
        }
        warn("期望获得 button(id:)，但实际为 \(result)")
        return buttons[0].id
    }
    
    public func onButtonTap(_ button: MessageBoxModel.Button) {
        log("按钮 \(button.label) 被点击")
        if let onClick = button.onClick {
            onClick()
        } else {
            DispatchQueue.main.async {
                self.continuation?.resume(returning: MessageBoxResult.button(id: button.id))
                self.continuation = nil
                self.currentMessageBox = nil
            }
        }
    }
    
    private func show(
        title: String,
        content: MessageBoxModel.Content,
        level: MessageBoxModel.Level,
        buttons: [MessageBoxModel.Button]
    ) async -> MessageBoxResult {
        await semaphore.wait()
        log("正在显示模态框 \(title)")
        defer { Task { await semaphore.signal() } }
        
        let model: MessageBoxModel = .init(
            title: title,
            content: content,
            level: level,
            buttons: buttons
        )
        await MainActor.run {
            self.currentMessageBox = model
        }
        
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }
    
    public enum MessageBoxResult {
        case button(id: Int)
        case listSelection(index: Int?)
        case input(text: String?)
    }
    
    private init() {}
}
