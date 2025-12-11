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
        let anyTask: AnyMyTask = .init(task) { task in
            DispatchQueue.main.async {
                self.tasks.removeAll(where: { $0.id == task.id })
            }
        }
        tasks.append(anyTask)
        Task {
            try await task.start()
            // TODO: 弹出 Hint
        }
    }
    
    private init() {}
}
