//
//  TasksPage.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/12/9.
//

import SwiftUI
import Core

struct TasksPage: View {
    @ObservedObject private var taskManager: TaskManager = .shared
    @StateObject private var loadingVM: MyLoadingViewModel = .init(text: "没有正在执行的任务")
    
    var body: some View {
        CardContainer {
            if Metadata.debugMode {
                MyCard("", titled: false) {
                    HStack {
                        MyButton("添加一个任务") {
                            let task: MyTask<EmptyModel> = .init(
                                name: "一个任务", model: EmptyModel(),
                                .init(0, "子任务1（等待 1s）") { _, _ in try await Task.sleep(seconds: 1) },
                                .init(0, "子任务2（与 子任务1 同时执行，等待 2s）") { task, _ in
                                    try await Task.sleep(seconds: 1)
                                    await task.setProgressAsync(0.5)
                                    try await Task.sleep(seconds: 1)
                                },
                                .init(1, "子任务3（等待 1s）") { _, _ in try await Task.sleep(seconds: 1) }
                            )
                            taskManager.execute(task: task)
                        }
                        .frame(width: 100)
                        Spacer()
                    }
                    .frame(height: 40)
                }
            }
            if taskManager.tasks.isEmpty {
                MyLoading(viewModel: loadingVM)
            } else {
                ForEach(taskManager.tasks.filter(\.display)) { task in
                    TaskCard(task)
                }
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
                ForEach(task.subTasks, id: \.name) { (subTask: AnyMyTask.SubTask) in
                    HStack {
                        Group {
                            if subTask.state == .executing {
                                MyText("\(Int(subTask.progress * 100))%", color: .color2)
                            } else {
                                Image(subTask.state.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(Color.color2)
                                    .frame(width: 20)
                            }
                        }
                        .frame(width: 40, height: 10)
                        MyText(subTask.name)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } action: {
            MyText("\(Int(totalProgress * 100))%", color: .color2)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
    
    private var totalProgress: Double {
        task.subTasks.reduce(0, { $0 + $1.progress }) / Double(task.subTasks.count)
    }
}
