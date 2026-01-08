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
                    MyCard("常规实例") {
                        VStack(spacing: 0) {
                            ForEach(instances, id: \.self) { instance in
                                InstanceView(instance: instance)
                                    .onTapGesture {
                                        instanceViewModel.switchInstance(to: instance, repository)
                                        AppRouter.shared.removeLast()
                                    }
                            }
                        }
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
}

private struct InstanceView: View {
    private let id: String
    private let version: MinecraftVersion
    
    init(instance: MinecraftRepository.Instance) {
        self.id = instance.id
        self.version = instance.version
    }
    
    var body: some View {
        MyListItem {
            HStack {
                Image("GrassBlock")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 35, height: 35)
                VStack {
                    MyText(id)
                    MyText(version.id, color: .colorGray3)
                }
                Spacer()
            }
        }
    }
}
