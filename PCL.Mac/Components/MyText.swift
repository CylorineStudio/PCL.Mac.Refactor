//
//  MyText.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/11/10.
//

import SwiftUI

struct MyText: View {
    private let text: AttributedString
    
    /// 创建一个富文本视图。
    ///
    /// `AttributedString` 没有设置字体或 `foregroundColor` 的部分将使用下方提供的参数。
    /// - Parameters:
    ///   - text: 包含文本内容的 `AttributedString`。
    ///   - size: 文本默认大小。
    ///   - color: 文本默认颜色。
    init(_ text: AttributedString, size: CGFloat = 14, color: Color = .color1) {
        self.text = text.applyingMissingDefaultStyle(size: size, color: color)
    }
    
    /// 创建一个普通文本视图。
    ///
    /// 文本字体为 `PCL English`。
    /// - Parameters:
    ///   - text: 文本内容。
    ///   - size: 文本大小。
    ///   - color: 文本颜色。
    init(_ text: String, size: CGFloat = 14, color: Color = .color1) {
        self.init(AttributedString(text), size: size, color: color)
    }
    
    var body: some View {
        Text(text)
    }
}

extension AttributedString {
    /// 基于当前 `AttributedString` 创建一个带有默认字体和颜色的 `AttributedString`。
    ///
    /// - Parameters:
    ///   - size: 新字符串的字号，默认为 `14`。
    ///   - color: 新字符串的颜色，默认为 `Color.color1`。
    /// - Returns: 一个新的 `AttributedString`。
    func applyingMissingDefaultStyle(size: CGFloat = 14, color: Color = .color1) -> AttributedString {
        let font = Font.custom("PCLEnglish", size: size)
        var result = self
        for run in result.runs {
            let range = run.range
            if run.font == nil {
                result[range].font = font
            }
            if run.foregroundColor == nil {
                result[range].foregroundColor = color
            }
        }
        return result
    }
}
