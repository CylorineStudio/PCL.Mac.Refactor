//
//  InstanceListPage.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/29.
//

import SwiftUI
import Core

struct InstanceListPage: View {
    @EnvironmentObject private var instanceViewModel: InstanceViewModel
    @EnvironmentObject private var viewModel: InstanceListViewModel
    @ObservedObject private var repository: MinecraftRepository
    
    init(repository: MinecraftRepository) {
        self.repository = repository
    }
    
    var body: some View {
        VStack {
            if let instances = repository.instances {
                CardContainer {
                    if let errorInstances = repository.errorInstances {
                        MyCard("错误的实例") {
                            VStack(spacing: 0) {
                                ForEach(errorInstances, id: \.name) { instance in
                                    MyListItem(.init(image: "RedstoneBlock", name: instance.name, description: instance.message))
                                }
                            }
                        }
                    }
                    MyCard("常规实例") {
                        VStack(spacing: 0) {
                            ForEach(instances.sorted(by: { $0.version > $1.version }), id: \.name) { instance in
                                InstanceView(instance: instance)
                                    .onTapGesture {
                                        instanceViewModel.switchInstance(to: instance, repository)
                                        AppRouter.shared.removeLast()
                                    }
                            }
                        }
                    }
                    .cardIndex(1)
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
}

private struct InstanceView: View {
    private let name: String
    private let version: MinecraftVersion
    
    init(instance: MinecraftInstance) {
        self.name = instance.name
        self.version = instance.version
    }
    
    var body: some View {
        MyListItem(.init(image: "GrassBlock", name: name, description: version.id))
    }
}
