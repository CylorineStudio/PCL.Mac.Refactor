//
//  HintManager.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/13.
//

import Foundation

class HintManager: ObservableObject {
    public static let shared: HintManager = .init()
    @Published public var hints: [HintModel] = []
    
    /// 弹出提示。
    /// - Parameters:
    ///   - text: 提示内容。
    ///   - type: 提示类型，默认为 `info`（蓝色）。
    ///   - time: 提示显示时长。
    public func hint(_ text: String, type: HintModel.`Type` = .info, time: Double = 2.0) {
        let hint: HintModel = .init(text: text, type: type)
        hints.append(hint)
        DispatchQueue.main.asyncAfter(deadline: .now() + time) {
            self.hints.removeAll(where: { $0.id == hint.id })
        }
    }
    
    private init() {}
}

/// 弹出提示。
/// - Parameters:
///   - text: 提示内容。
///   - type: 提示类型，默认为 `info`（蓝色）。
///   - time: 提示显示时长。
func hint(_ text: String, type: HintModel.`Type` = .info, time: Double = 2.0) {
    DispatchQueue.main.async {
        HintManager.shared.hint(text, type: type, time: time)
    }
}
