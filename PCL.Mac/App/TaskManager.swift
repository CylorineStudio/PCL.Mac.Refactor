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
            do {
                try await task.start()
            } catch {
                // TODO: 弹出 Hint
            }
            await MainActor.run {
                tasks.removeAll(where: { $0.id == task.id })
            }
            // TODO: 弹出 Hint
        }
    }
    
    private init() {}
}
