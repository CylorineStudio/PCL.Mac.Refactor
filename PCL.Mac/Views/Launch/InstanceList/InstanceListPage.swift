//
//  InstanceListPage.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/12/29.
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
            if let instances = viewModel.instances {
                CardContainer {
                    MyCard("当前目录：\(repository.name)", foldable: false) {
                        infoLine(label: "路径") { MyText(repository.url.path).textSelection(.enabled) }
                            .padding(.top, 6)
                        infoLine(label: "实例数量") { MyText(instances.count.description) }
                        
                        HStack(spacing: 15) {
                            MyButton("更改显示名称") {
                                MessageBoxManager.shared.showInput(title: "输入新名称") { name in
                                    guard let name, !name.isEmpty else { return }
                                    repository.name = name
                                    AppRouter.shared.setRoot(.launch)
                                    AppRouter.shared.append(.instanceList(repository))
                                    hint("已将目录名称更改为 \(name)！", type: .finish)
                                }
                            }
                            .frame(width: 150)
                            MyButton("移除目录", type: .red) {
                                MessageBoxManager.shared.showText(
                                    title: "确认",
                                    content: "你确定要移除这个目录（\(repository.url.path)）吗？\n这只会把它从启动器的目录列表中移除，而不会删除任何文件。",
                                    level: .info,
                                    .no(), .yes()
                                ) { button in
                                    guard button == 1 else { return }
                                    instanceViewModel.removeRepository(repository)
                                    AppRouter.shared.removeLast()
                                    hint("移除成功！", type: .finish)
                                }
                            }
                            .frame(width: 150)
                            Spacer()
                        }
                        .frame(height: 35)
                        .padding(.top, 6)
                    }
                    if let errorInstances = viewModel.errorInstances, !errorInstances.isEmpty {
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
            viewModel.load(repository)
        }
        .id(repository.url)
    }
    
    private func compareInstance(lhs: MinecraftInstance, rhs: MinecraftInstance) -> Bool {
        if lhs.modLoader == rhs.modLoader {
            return lhs.version > rhs.version
        }
        return (lhs.modLoader?.index ?? -1) > (rhs.modLoader?.index ?? -1)
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
    
    @ViewBuilder
    private func infoLine(label: String,  @ViewBuilder body: () -> some View) -> some View {
        HStack(spacing: 20) {
            MyText(label)
                .frame(width: 120, alignment: .leading)
            HStack {
                Spacer(minLength: 0)
                body()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 1)
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
            self.iconName = modLoader.icon
        } else {
            self.iconName = "GrassBlock"
        }
    }
    
    var body: some View {
        MyListItem(.init(image: iconName, name: name, description: version.id))
    }
}
