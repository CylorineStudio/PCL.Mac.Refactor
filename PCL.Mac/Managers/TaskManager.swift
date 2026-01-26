//
//  TaskManager.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/11.
//

import Foundation
import Core

public class TaskManager: ObservableObject {
    public static let shared: TaskManager = .init()
    
    @Published public private(set) var tasks: [AnyMyTask] = []
    
    public func execute<Model>(task: MyTask<Model>) {
        tasks.append(AnyMyTask(task))
        Task {
            var e: Error?
            do {
                try await task.start()
            } catch {
                e = error
            }
            let error = e
            await MainActor.run {
                tasks.removeAll(where: { $0.id == task.id })
                if let error {
                    hint("任务 \(task.name) 执行失败：\(error.localizedDescription)", type: .critical)
                } else {
                    hint("任务 \(task.name) 执行完成", type: .finish)
                }
            }
        }
    }
    
    private init() {}
}
