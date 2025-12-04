//
//  MyTask.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/3.
//

import Foundation
import Combine

public class MyTask: ObservableObject {
    public let subTasks: [SubTask]
    private var cancellables: [AnyCancellable] = []
    
    public init(_ subTasks: SubTask...) {
        self.subTasks = subTasks
        cancellables = subTasks.map { (subTask: SubTask) in
            subTask.objectWillChange.sink { [weak self] _ in
                self?.objectWillChange.send()
            }
        }
    }
    
    public func execute() async throws {
        guard !subTasks.isEmpty else {
            warn("subTasks 为空")
            return
        }
        if let task = subTasks.first(where: { $0.ordinal < 0 }) {
            throw TaskError.invalidOrdinal(value: task.ordinal)
        }
        let maxOrdinal: Int = subTasks.map(\.ordinal).max()!
        let subTaskLists: [[SubTask]] = subTasks.reduce(into: Array(repeating: [], count: maxOrdinal + 1)) { result, subTask in
            result[subTask.ordinal].append(subTask)
        }
        for subTaskList in subTaskLists {
            try await execute(taskList: subTaskList)
        }
    }
    
    private func execute(taskList: [SubTask]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { (group: inout ThrowingTaskGroup<Void, Error>) in
            for task in taskList {
                group.addTask {
                    try await task.execute()
                }
            }
            for try await _ in group { }
        }
    }
    
    public class SubTask: ObservableObject {
        @MainActor @Published public var progress: Double = 0
        public let ordinal: Int
        public let name: String
        private let start: (SubTask) async throws -> Void
        
        /// 创建一个子任务。
        /// - Parameters:
        ///   - ordinal: 该子任务在 `MyTask` 中的执行顺序，数值越小则越先执行，不能小于 0。
        ///   - name: 子任务名。
        ///   - start: 子任务的开始函数。
        public init(
            _ ordinal: Int,
            _ name: String,
            _ start: @escaping (SubTask) async throws -> Void
        ) {
            self.ordinal = ordinal
            self.name = name
            self.start = start
        }
        
        public func execute() async throws {
            log("正在执行子任务 \(name)")
            do {
                try await start(self)
            } catch {
                err("子任务 \(name) 执行失败：\(error.localizedDescription)")
                throw error
            }
            log("子任务 \(name) 执行完成")
        }
    }
}
