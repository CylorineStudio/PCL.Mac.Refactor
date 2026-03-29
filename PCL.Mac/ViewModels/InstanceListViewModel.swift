//
//  InstanceListViewModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/1/8.
//

import Foundation
import Core

class InstanceListViewModel: ObservableObject {
    @Published public var instances: [MinecraftInstance]?
    @Published public var errorInstances: [MinecraftRepository.ErrorInstance]?
    @Published public var loadTask: Task<Void, Error>?
    public let loadingViewModel: MyLoadingViewModel = .init(text: "加载中")
    
    /// 启动 `MinecraftRepository` 加载任务。
    @MainActor
    public func load(_ repository: MinecraftRepository) {
        if loadTask != nil { return }
        reset()
        repository.instances = nil
        loadTask = Task.detached {
            do {
                try await repository.loadAsync()
            } catch {
                err("加载实例列表失败：\(error.localizedDescription)")
                await MainActor.run {
                    self.loadingViewModel.fail(with: "加载失败：\(error.localizedDescription)")
                }
            }
            await MainActor.run {
                self.instances = repository.instances
                self.errorInstances = repository.errorInstances
                self.loadTask = nil
            }
        }
    }
    
    @MainActor
    public func reset() {
        instances = nil
        errorInstances = nil
        loadingViewModel.reset()
    }
}
