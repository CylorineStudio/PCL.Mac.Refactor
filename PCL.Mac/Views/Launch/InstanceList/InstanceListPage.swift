//
//  InstanceListPage.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/29.
//

import SwiftUI
import Core

struct InstanceListPage: View {
    @EnvironmentObject private var viewModel: InstanceViewModel
    @ObservedObject private var repository: MinecraftRepository
    @State private var error: Error?
    
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
                                        viewModel.switchInstance(to: instance, repository)
                                        AppRouter.shared.removeLast()
                                    }
                            }
                        }
                    }
                }
            } else {
                MyCard("", titled: false) {
                    if let error {
                        MyText("加载版本列表失败：\(error.localizedDescription)", size: 16, color: .red)
                    } else {
                        MyText("加载中", size: 16, color: .color3)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            if repository.instances != nil { return }
            Task {
                do {
                    try await repository.loadAsync()
                } catch {
                    err("加载实例列表失败：\(error.localizedDescription)")
                    await MainActor.run {
                        self.error = error
                    }
                }
            }
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
