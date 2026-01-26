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
    public static let cancelButtonID: Int = 1000
    public static let okButtonID: Int = 1001
    @Published public private(set) var currentMessageBox: MessageBoxModel?
    private let defaultButton: MessageBoxModel.Button = .init(id: 0, label: "确定", type: .normal)
    private let semaphore: AsyncSemaphore = .init(value: 1)
    private var continuation: CheckedContinuation<MessageBoxResult, Never>?
    /// 在弹出下一个弹窗时，是否需要等待。
    private var shouldWait: Bool = false
    /// 清除等待状态的 `DispatchWorkItem`。
    private var clearWaitStateWorkItem: DispatchWorkItem?
    
    /// 弹出一个带有纯文本内容的模态框。
    /// - Parameters:
    ///   - title: 模态框标题。
    ///   - content: 文本内容。
    ///   - level: 模态框等级，控制了模态框的颜色。
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
    
    /// 弹出一个带有列表的模态框。
    /// - Parameters:
    ///   - title: 模态框标题。
    ///   - items: 列表项。
    /// - Returns: 选择的列表项的索引。如果用户点击了取消，或发生内部错误，返回 `nil`。
    public func showList(title: String, items: [ListItem]) async -> Int? {
        let result: MessageBoxResult = await show(
            title: title,
            content: .list(items: items),
            level: .info,
            buttons: [.init(id: MessageBoxManager.cancelButtonID, label: "取消", type: .normal), .init(id: MessageBoxManager.okButtonID, label: "确定", type: .highlight)]
        )
        if case .listSelection(let index) = result {
            return index
        }
        warn("期望获得 listSelection(index:)，但实际为 \(result)")
        return nil
    }
    
    /// 弹出一个带有输入框的模态框。
    /// - Parameters:
    ///   - title: 模态框标题。
    ///   - initialContent: 输入框的起始文本。
    ///   - placeholder: 占位符。
    /// - Returns: 输入的文本。如果用户点击了取消，或发生内部错误，返回 `nil`。
    public func showInput(title: String, initialContent: String? = nil, placeholder: String? = nil) async -> String? {
        let result: MessageBoxResult = await show(
            title: title,
            content: .input(initialContent: initialContent, placeholder: placeholder),
            level: .info,
            buttons: [.init(id: MessageBoxManager.cancelButtonID, label: "取消", type: .normal), .init(id: MessageBoxManager.okButtonID, label: "确定", type: .highlight)]
        )
        if case .input(let text) = result {
            return text
        }
        warn("期望获得 input(text:)，但实际为 \(result)")
        return nil
    }
    
    public func onButtonTap(_ button: MessageBoxModel.Button) {
        log("按钮 \(button.label) 被点击")
        if let onClick = button.onClick {
            onClick()
        } else {
            complete(with: .button(id: button.id))
        }
    }
    
    public func onListSelect(index: Int?) {
        complete(with: .listSelection(index: index))
    }
    
    public func onInputFinished(text: String?) {
        complete(with: .input(text: text))
    }
    
    private func complete(with result: MessageBoxResult) {
        DispatchQueue.main.async {
            self.continuation?.resume(returning: result)
            self.continuation = nil
            self.currentMessageBox = nil
        }
        let workItem: DispatchWorkItem = .init {
            self.shouldWait = false
        }
        self.clearWaitStateWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: workItem)
    }
    
    private func show(
        title: String,
        content: MessageBoxModel.Content,
        level: MessageBoxModel.Level,
        buttons: [MessageBoxModel.Button]
    ) async -> MessageBoxResult {
        await semaphore.wait()
        clearWaitStateWorkItem?.cancel()
        if shouldWait {
            try? await Task.sleep(seconds: 0.5)
        } else {
            shouldWait = true
        }
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
