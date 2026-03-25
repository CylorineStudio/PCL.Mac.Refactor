//
//  MessageBoxModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/1/20.
//

import SwiftUI

struct MessageBoxModel: Equatable, Identifiable {
    public let id: UUID = .init()
    public let title: String
    public let content: Content
    public let level: Level
    public let buttons: [Button]
    
    public enum Content {
        case text(text: String)
        case list(items: [ListItem])
        case input(initialContent: String?, placeholder: String?)
    }
    
    public enum Level {
        case info, error
    }
    
    public static func == (lhs: MessageBoxModel, rhs: MessageBoxModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    public struct Button {
        public let id: Int
        public let label: String
        public let type: MyButton.`Type`
        public let onClick: (() -> Void)?
        
        /// 创建一个弹窗按钮。
        /// - Parameters:
        ///   - onClick: 点击回调，有值时被点击后不会关闭弹窗。
        public init(id: Int, label: String, type: MyButton.`Type`, onClick: (() -> Void)? = nil) {
            self.id = id
            self.label = label
            self.type = type
            self.onClick = onClick
        }
        
        /// 创建一个 `id` 为 `1` 的“是”按钮。
        /// - Parameters:
        ///   - label: 按钮文本，默认为 `"确认"`。
        ///   - type: 按钮类型，默认为 `.normal`。
        public static func yes(label: String = "确认", type: MyButton.`Type` = .normal) -> Button {
            return .init(id: 1, label: label, type: type)
        }
        
        /// 创建一个 `id` 为 `0` 的“否”按钮。
        /// - Parameters:
        ///   - label: 按钮文本，默认为 `"取消"`。
        ///   - type: 按钮类型，默认为 `.normal`。
        public static func no(label: String = "取消", type: MyButton.`Type` = .normal) -> Button {
            return .init(id: 0, label: label, type: type)
        }
    }
}
