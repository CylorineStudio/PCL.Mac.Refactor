//
//  MessageBoxModel.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/20.
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
    }
}
