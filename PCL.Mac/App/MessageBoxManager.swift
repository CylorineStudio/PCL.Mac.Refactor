//
//  MessageBoxManager.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/20.
//

import Foundation

class MessageBoxManager: ObservableObject {
    public static let shared: MessageBoxManager = .init()
    @Published public private(set) var currentMessageBox: MessageBoxModel?
    
    public func showText(title: String, body: String, level: MessageBoxModel.Level = .info) {
        currentMessageBox = .init(title: title, body: .text(text: body), level: level)
    }
    
    public func close() {
        currentMessageBox = nil
    }
    
    private init() {}
}
