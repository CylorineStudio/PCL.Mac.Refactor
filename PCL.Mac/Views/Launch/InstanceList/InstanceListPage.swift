//
//  InstanceListPage.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/29.
//

import SwiftUI
import Core

struct InstanceListPage: View {
    @EnvironmentObject private var instanceViewModel: InstanceManager
    @EnvironmentObject private var viewModel: InstanceListViewModel
    @ObservedObject private var repository: MinecraftRepository
    
    init(repository: MinecraftRepository) {
        self.repository = repository
    }
    
    var body: some View {
        VStack {
            if let instances = repository.instances {
                CardContainer {
                    if let errorInstances = repository.errorInstances, !errorInstances.isEmpty {
                        MyCard("错误的实例") {
                            VStack(spacing: 0) {
                                ForEach(errorInstances, id: \.name) { instance in
                                    MyListItem(.init(image: "RedstoneBlock", name: instance.name, description: instance.message))
                                }
                            }
                        }
                    }
                    let moddedInstances: [MinecraftInstance] = instances.filter { $0.modLoader != nil }
                    if !moddedInstances.isEmpty {
                        MyCard("可安装 Mod") {
                            instanceList(moddedInstances)
                        }
                        .cardIndex(1)
                    }
                    let vanillaInstances: [MinecraftInstance] = instances.filter { !moddedInstances.contains($0) }
                    if !vanillaInstances.isEmpty {
                        MyCard("常规实例") {
                            instanceList(vanillaInstances)
                        }
                        .cardIndex(moddedInstances.isEmpty ? 1 : 2)
                    }
                }
            } else {
                MyLoading(viewModel: viewModel.loadingViewModel)
            }
        }
        .onAppear {
            if repository.instances != nil { return }
            viewModel.reloadAsync(repository)
        }
        .id(repository.url)
    }
    
    private func compareInstance(lhs: MinecraftInstance, rhs: MinecraftInstance) -> Bool {
        if lhs.modLoader == rhs.modLoader {
            return lhs.version > rhs.version
        }
        return (lhs.modLoader?.rawValue ?? -1) > (rhs.modLoader?.rawValue ?? -1)
    }
    
    @ViewBuilder
    private func instanceList(_ instances: [MinecraftInstance]) -> some View {
        VStack(spacing: 0) {
            ForEach(instances.sorted(by: compareInstance(lhs:rhs:)), id: \.name) { instance in
                InstanceView(instance: instance)
                    .onTapGesture {
                        instanceViewModel.switchInstance(to: instance, repository)
                        AppRouter.shared.removeLast()
                    }
            }
        }
    }
}

private struct InstanceView: View {
    private let name: String
    private let version: MinecraftVersion
    private let iconName: String
    
    init(instance: MinecraftInstance) {
        self.name = instance.name
        self.version = instance.version
        if let modLoader = instance.modLoader {
            self.iconName = modLoader.description
        } else {
            self.iconName = "GrassBlock"
        }
    }
    
    var body: some View {
        MyListItem(.init(image: iconName, name: name, description: version.id))
    }
}
