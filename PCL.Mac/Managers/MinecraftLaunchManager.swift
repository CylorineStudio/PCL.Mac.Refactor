//
//  MinecraftLaunchManager.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/2/6.
//

import Foundation
import Core
import Combine

class MinecraftLaunchManager: ObservableObject {
    public static let shared: MinecraftLaunchManager = .init()
    
    @Published public var launching: Bool = false
    @Published public var progress: Double = 0
    @Published public var currentStage: String? = nil
    @Published public var instanceName: String?
    public let loadingModel: MyLoadingViewModel = .init(text: "正在启动游戏")
    
    private var task: MyTask<MinecraftLaunchTask.Model>? {
        didSet {
            launching = task != nil
            subscribeToTask()
        }
    }
    private var cancellables: [AnyCancellable] = []
    
    /// 开始启动游戏。
    /// - Parameters:
    ///   - instance: 目标游戏实例。
    ///   - account: 使用的账号。
    ///   - repository: 实例所在的游戏仓库。
    /// - Returns: 一个布尔值，表示是否成功添加任务。
    public func launch(
        _ instance: MinecraftInstance,
        using account: Account,
        in repository: MinecraftRepository
    ) -> Bool {
        if launching { return false }
        self.loadingModel.text = "正在启动游戏"
        let task: MyTask<MinecraftLaunchTask.Model> = MinecraftLaunchTask.create(for: instance, using: account, in: repository) { process in
            self.loadingModel.text = "已启动游戏"
        }
        TaskManager.shared.execute(task: task, display: false) { _ in
            self.task = nil
            self.currentStage = nil
            self.instanceName = nil
            self.progress = 0
        }
        self.instanceName = instance.name
        self.task = task
        return true
    }
    
    /// 取消当前启动任务。
    public func cancel() {
        if let task {
            TaskManager.shared.cancel(task.id)
        }
    }
    
    private func subscribeToTask() {
        cancellables.removeAll()
        guard let task else { return }
        task.$currentTaskOrdinal
            .map { [weak self] ordinal in
                guard let ordinal else {
                    return nil
                }
                return self?.stageString(for: ordinal)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentStage, on: self)
            .store(in: &cancellables)
        
        task.$progress
            .receive(on: DispatchQueue.main)
            .assign(to: \.progress, on: self)
            .store(in: &cancellables)
    }
    
    private func stageString(for ordinal: Int) -> String {
        switch ordinal {
        case 0: "检查 Java"
        case 1: "刷新账号"
        case 2: "预检查"
        case 3: "检查资源完整性"
        case 4: "启动游戏"
        case 5: "等待游戏窗口出现"
        default: "\(ordinal)"
        }
    }
    
    private init() {}
}
