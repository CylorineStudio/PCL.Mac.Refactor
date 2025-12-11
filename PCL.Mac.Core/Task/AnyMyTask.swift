//
//  AnyMyTask.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/9.
//

import Foundation
import Combine

public class AnyMyTask: ObservableObject, Identifiable {
    public typealias ModelType = any TaskModel
    
    public let id: UUID
    public let name: String
    private let _subTasks: () -> [(name: String, progress: Double, state: SubTaskState)]
    private var cancellable: AnyCancellable?
    
    public init<Model>(_ task: MyTask<Model>, completion: @escaping (AnyMyTask) -> Void) where Model: TaskModel {
        self.id = task.id
        self.name = task.name
        self._subTasks = {
            task.subTasks.map { (name: $0.name, progress: $0.progress, state: $0.state) }
        }
        self.cancellable = task.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        task.setCompletion { _ in completion(self) }
    }
    
    public var subTasks: [(name: String, progress: Double, state: SubTaskState)] { _subTasks() }
}
