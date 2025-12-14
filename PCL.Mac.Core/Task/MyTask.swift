//
//  MyTask.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/3.
//

import Foundation
import Combine

/// 下载 / 安装任务，支持并发执行多个子任务与数据共享。
/// 实现了 `ObservableObject`，会在子任务状态与进度变化时刷新视图。
/// 使用示例：
/// ```swift
/// let task: MyTask<EmptyModel> = .init(
///     name: "一个示例任务", model: EmptyModel(),
///     .init(0, "子任务1（等待 1s）") { _,_ in try await Task.sleep(seconds: 1) },
///     .init(0, "子任务2（与 子任务1 同时执行，等待 2s）") { task, _ in
///         try await Task.sleep(seconds: 1)
///         await task.setProgressAsync(0.5)
///         try await Task.sleep(seconds: 1)
///     },
///     .init(1, "子任务3（等待 1s）") { _,_ in try await Task.sleep(seconds: 1) }
/// )
/// try await task.start()
/// ```
public class MyTask<Model: TaskModel>: ObservableObject, Identifiable {
    public let id: UUID = .init()
    public let name: String
    public let subTasks: [SubTask]
    private let model: Model
    private var cancellables: [AnyCancellable] = []
    
    /// 创建一个任务。
    /// - Parameters:
    ///   - name: 任务名。
    ///   - model: 任务模型，用于在子任务间共享数据。
    ///   - subTasks: 该任务的子任务列表。
    public init(name: String, model: Model, _ subTasks: SubTask...) {
        self.name = name
        self.model = model
        self.subTasks = subTasks
        cancellables = subTasks.map { subTask in
            subTask.objectWillChange.sink { [weak self] _ in
                self?.objectWillChange.send()
            }
        }
    }
    
    /// 开始按顺序执行任务。
    /// 执行时，会按 `ordinal` 将 `subTasks` 分组，`ordinal` 越小的越先执行。
    public func start() async throws {
        guard !subTasks.isEmpty else {
            warn("subTasks 为空")
            return
        }
        if let task = subTasks.first(where: { $0.ordinal < 0 }) {
            throw TaskError.invalidOrdinal(value: task.ordinal)
        }
        let maxOrdinal: Int = subTasks.map(\.ordinal).max()!
        let subTaskLists: [[SubTask]] = subTasks.reduce(into: Array(repeating: [], count: maxOrdinal + 1)) { $0[$1.ordinal].append($1) }
        log("正在执行任务 \(name)")
        for subTaskList in subTaskLists {
            try await execute(taskList: subTaskList)
        }
        log("任务 \(name) 执行完成")
    }
    
    private func execute(taskList: [SubTask]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for task in taskList {
                group.addTask {
                    try await task.start(self.model)
                }
            }
            for try await _ in group { }
        }
    }
    
    /// `MyTask` 的子任务，支持进度与状态显示。
    public class SubTask: ObservableObject {
        @Published public private(set) var progress: Double = 0
        @Published public private(set) var state: SubTaskState = .waiting
        public let ordinal: Int
        public let name: String
        private let execute: (SubTask, Model) async throws -> Void
        
        /// 创建一个子任务。
        /// - Parameters:
        ///   - ordinal: 该子任务在 `MyTask` 中的执行顺序，数值越小则越先执行，不能小于 0。
        ///   - name: 子任务名。
        ///   - start: 子任务的开始函数。
        public init(
            _ ordinal: Int,
            _ name: String,
            _ execute: @escaping (SubTask, Model) async throws -> Void
        ) {
            self.ordinal = ordinal
            self.name = name
            self.execute = execute
        }
        
        fileprivate func start(_ model: Model) async throws {
            log("正在执行子任务 \(name)")
            await setState(.executing)
            do {
                try await execute(self, model)
            } catch {
                err("子任务 \(name) 执行失败：\(error.localizedDescription)")
                await setState(.failed)
                throw error
            }
            log("子任务 \(name) 执行完成")
            await setState(.finished)
            await setProgressAsync(1)
        }
        
        @MainActor
        public func setProgress(_ progress: Double) {
            self.progress = progress
        }
        
        public func setProgressAsync(_ progress: Double) async {
            await MainActor.run {
                self.setProgress(progress)
            }
        }
        
        private func setState(_ state: SubTaskState) async {
            await MainActor.run {
                self.state = state
            }
        }
    }
}

public enum SubTaskState {
    case waiting, executing, finished, failed
}
