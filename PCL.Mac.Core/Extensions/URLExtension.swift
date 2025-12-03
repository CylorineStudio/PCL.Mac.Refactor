//
//  URLExtension.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/3.
//

import Foundation

public extension URL {
    /// 返回一个新 URL，将给定的字符串路径拼接到当前 URL 末尾。
    ///
    /// - Parameter path: 需要追加的子路径（无需带斜杠前缀）。
    /// - Returns: 拼接后的新 URL。如果原 URL 不是 file 类型，行为与 macOS 13 保持一致。
    ///
    /// 如果原 URL 末尾已有斜杠，则直接添加子路径；
    /// 否则自动插入斜杠。追加路径时不会移除原有查询参数和片段。
    ///
    /// 示例：
    /// ```swift
    /// let baseURL = URL(string: "https://example.com/api")!
    /// let newURL = baseURL.appending(path: "v1/user") // https://example.com/api/v1/user
    /// ```
    func appending(path: String) -> URL {
        var url: URL = self
        for component in path.split(separator: "/") {
            url = url.appendingPathComponent(String(component))
        }
        return url
    }
}
