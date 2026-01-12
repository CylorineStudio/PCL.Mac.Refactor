//
//  InstanceListViewModel.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/8.
//

import Foundation
import Core

class InstanceListViewModel: ObservableObject {
    @Published var loadingViewModel: MyLoadingViewModel = .init(text: "加载中")
    @Published var loadTask: Task<Void, Error>?
    
    /// 重新加载 `MinecraftRepository` 的实例列表。
    public func reload(_ repository: MinecraftRepository) {
        reset()
        repository.instances = nil
        do {
            try repository.load()
        } catch {
            err("加载实例列表失败：\(error.localizedDescription)")
            loadingViewModel.fail(with: "加载失败：\(error.localizedDescription)")
        }
    }
    
    /// 异步重新加载 `MinecraftRepository` 的实例列表。
    public func reloadAsync(_ repository: MinecraftRepository) {
        if loadTask != nil { return }
        reset()
        repository.instances = nil
        loadTask = Task {
            do {
                try await repository.loadAsync()
            } catch {
                err("加载实例列表失败：\(error.localizedDescription)")
                await MainActor.run {
                    loadingViewModel.fail(with: "加载失败：\(error.localizedDescription)")
                }
            }
            await MainActor.run {
                loadTask = nil
            }
        }
    }
    
    public func reset() {
        loadingViewModel.reset()
    }
}
