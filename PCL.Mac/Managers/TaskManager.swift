//
//  TaskManager.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/12/11.
//

import Foundation
import Combine
import Core

public class TaskManager: ObservableObject {
    public static let shared: TaskManager = .init()
    
    @Published public private(set) var tasks: [AnyMyTask] = []
    @Published public private(set) var downloadSpeed: Int64 = 0
    private var executorTasks: [UUID: Task<Void, Never>] = [:]
    private var cancellables: [AnyCancellable] = []
    
    /// 开始执行一个任务。
    /// - Parameters:
    ///   - task: 待执行的任务。
    ///   - display: 是否显示与弹出 hint。
    ///   - completion: 任务完成回调。
    /// - Returns: 任务的 `id`。
    @discardableResult
    public func execute<Model>(task: MyTask<Model>, display: Bool = true, completion: ((Error?) -> Void)? = nil) -> UUID {
        let id: UUID = task.id
        tasks.append(.init(task, display: display))
        let executorTask = Task {
            var e: Error?
            do {
                try await task.start()
            } catch is CancellationError {
            } catch {
                e = error
            }
            let error = e
            await MainActor.run {
                if display {
                    if let error {
                        hint("任务 \(task.name) 执行失败：\(error.localizedDescription)", type: .critical)
                    } else {
                        hint("任务 \(task.name) 执行完成", type: .finish)
                    }
                }
                completion?(error)
                self.clean(for: id)
            }
        }
        executorTasks[id] = executorTask
        return id
    }
    
    /// 取消执行正在执行的任务.
    /// - Parameter id: 任务的 `id`。
    public func cancel(_ id: UUID) {
        if let task = executorTasks[id] {
            task.cancel()
            clean(for: id)
        }
    }
    
    private func clean(for id: UUID) {
        tasks.removeAll(where: { $0.id == id })
        executorTasks.removeValue(forKey: id)
    }
    
    private init() {
        DownloadSpeedManager.shared.$currentSpeed
            .receive(on: DispatchQueue.main)
            .assign(to: \.downloadSpeed, on: self)
            .store(in: &cancellables)
    }
}
