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
        try await MyTask<TestModel>(name: "empty", model: .init()).start()
        let _ = await #expect(throws: TaskError.invalidOrdinal(value: -1)) {
            try await MyTask<TestModel>(name: "Invalid ordinal", model: .init(), .init(-1, "", { _, _ in })).start()
        }
        let _ = await #expect(throws: TaskError.unknownError) {
            try await MyTask<TestModel>(name: "Error", model: .init(), .init(0, "", { _, _ in throw TaskError.unknownError })).start()
        }
        
        let task: MyTask<TestModel> = .init(
            name: "Model test", model: .init(),
            .init(0, "下载客户端清单") { _, model in
                model.value = 1
                debug("model.value = 1")
            },
            .init(1, "下载散列资源") { _, model in
                model.value += 1
                debug("model.value += 1")
            },
            .init(2, "解压本地库") { _, model in
                debug("model.value is: \(model.value)")
            },
            .init(1, "下载依赖库") { _, model in
                model.value += 1
                debug("model.value += 1")
            },
            .init(1, "下载客户端 JAR") { _, model in
                model.value += 1
                debug("model.value += 1")
            }
        )
        try await task.start()
    }
}

private class TestModel: TaskModel {
    public var value: Int = 0
    required init() {}
}
