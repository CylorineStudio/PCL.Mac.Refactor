//
//  TasksPage.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/9.
//

import SwiftUI
import Core

struct TasksPage: View {
    @ObservedObject private var taskManager: TaskManager = .shared
    
    var body: some View {
        CardContainer {
            MyCard("", titled: false) {
                HStack {
                    MyButton("添加一个任务") {
                        let task: MyTask<EmptyModel> = .init(
                            name: "一个任务", model: EmptyModel(),
                            .init(0, "子任务1（等待 1s）") { _,_ in try await Task.sleep(seconds: 1) },
                            .init(0, "子任务2（与 子任务1 同时执行，等待 2s）") { _,_ in try await Task.sleep(seconds: 2) },
                            .init(1, "子任务3（等待 1s）") { _,_ in try await Task.sleep(seconds: 1) }
                        )
                        taskManager.execute(task: task)
                    }
                    .frame(width: 100)
                    Spacer()
                }
                .frame(height: 40)
            }
            ForEach(taskManager.tasks) { task in
                TaskCard(task)
            }
        }
    }
}

private struct TaskCard: View {
    @ObservedObject private var task: AnyMyTask
    
    init(_ task: AnyMyTask) {
        self.task = task
    }
    
    var body: some View {
        MyCard(task.name, foldable: false) {
            VStack(alignment: .leading) {
                ForEach(task.subTasks, id: \.name) { subTask in
                    MyText("\(subTask.name) \(subTask.state)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
