//
//  Compatibility.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/9.
//

import Foundation

// 将高于 Minimum Deployment 的 macOS 版本中新增的函数移植到旧版本，以兼容旧版 macOS，并且不改动现有代码。

public extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

public extension URL {
    func appending(path: String) -> URL {
        var url: URL = self
        for component in path.split(separator: "/") {
            url = url.appendingPathComponent(String(component))
        }
        return url
    }
}
