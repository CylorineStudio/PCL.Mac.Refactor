//
//  MyTaskTests.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/4.
//

import Testing
import Foundation
import Core

struct MyTaskTests {
    @Test func test() async throws {
        let task: MyTask = .init(
            .init(0, "下载客户端清单") { _ in },
            .init(1, "下载散列资源") { _ in },
            .init(2, "解压本地库") { _ in },
            .init(1, "下载依赖库") { _ in },
            .init(1, "下载客户端 JAR") { _ in }
        )
        try await task.execute()
    }
}
