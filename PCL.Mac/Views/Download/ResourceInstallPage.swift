//
//  ResourceInstallPage.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/19.
//

import SwiftUI
import Core

struct ResourceInstallPage: View {
    @StateObject private var viewModel: ResourceInstallViewModel
    @State private var currentPage: Int = 0
    
    init(project: ProjectListItemModel) {
        self._viewModel = StateObject(wrappedValue: .init(project: project))
    }
    
    var body: some View {
        CardContainer {
            MyCard("", titled: false) {
                ProjectListItemView(project: viewModel.project)
            }
            if viewModel.loaded, let versionList = viewModel.versionList {
                if currentPage == 0, let selectedVersionGroup = viewModel.selectedVersionGroup {
                    versionCard(versionGroup: selectedVersionGroup, isSelected: true, folded: false)
                }
                PaginatedContainer(versionList, id: \.0, currentPage: $currentPage, viewsPerPage: 10) { versionGroup in
                    versionCard(versionGroup: versionGroup, folded: versionList.count == 1 ? false : true)
                }
            } else {
                MyLoading(viewModel: viewModel.loadingVM)
                    .cardIndex(1)
            }
        }
        .task(id: viewModel.project) {
            do {
                try await viewModel.load(selectedInstance: InstanceManager.shared.currentInstance)
            } catch is CancellationError {
            } catch {
                err("加载\(viewModel.project.type) \(viewModel.project.title) 版本列表失败：\(error.localizedDescription)")
                viewModel.loadingVM.fail(with: "加载版本列表失败：\(error.localizedDescription)")
            }
        }
    }
    
    private func onVersionTap(_ version: ProjectVersionModel) async throws {
        guard let instance: MinecraftInstance = InstanceManager.shared.currentInstance else {
            hint("请先安装并选择一个实例！", type: .critical)
            return
        }
        
        do {
            try viewModel.checkInstance(instance, withVersion: version)
        } catch let error as ResourceInstallViewModel.InstanceCheckError {
            log("当前实例不满足该版本要求：\(error.localizedDescription)")
            switch error {
            case .versionUnsupported:
                if await MessageBoxManager.shared.showTextAsync(
                    title: "当前实例不符合要求",
                    content: "\(error.localizedDescription)\n你可以选择继续安装，但游戏可能会发生崩溃或无法正常游玩。\n是否继续安装？",
                    level: .error,
                    .no(),
                    .yes(label: "继续", type: .red)
                ) != 1 {
                    return
                }
            default:
                _ = await MessageBoxManager.shared.showTextAsync(
                    title: "当前实例不符合要求",
                    content: error.localizedDescription,
                    level: .error
                )
                return
            }
        }
        
        if await MessageBoxManager.shared.showTextAsync(
            title: "确认",
            content: "确定要安装 \(viewModel.project.title) \(version.version) 吗？",
            level: .info,
            .no(),
            .yes(type: .highlight)
        ) == 1 {
            do {
                let task = try await viewModel.createInstallTask(forVersion: version, to: instance)
                TaskManager.shared.execute(task: task)
                AppRouter.shared.append(.tasks)
            }
        }
    }
    
    private func onModpackTap(_ version: ProjectVersionModel) async throws {
        guard let repository: MinecraftRepository = InstanceManager.shared.currentRepository else {
            hint("请先选择一个游戏目录！", type: .critical)
            return
        }
        
        guard await MessageBoxManager.shared.showTextAsync(
            title: "确认",
            content: "确定要安装整合包 \(viewModel.project.title) \(version.version) 吗？",
            level: .info,
            .no(),
            .yes(type: .highlight)
        ) == 1 else { return }
        
        hint("开始下载整合包……")
        
        let (downloadTask, destination): (MyTask<EmptyModel>, URL)
        do {
            (downloadTask, destination) = try viewModel.createModpackDownloadTask(version)
        } catch {
            err("创建下载任务失败：\(error.localizedDescription)")
            hint("创建下载任务失败：\(error.localizedDescription)", type: .critical)
            return
        }
        
        let downloadExecutorTask: Task<Void, Error> = TaskManager.shared.execute(task: downloadTask)
        do {
            try await downloadExecutorTask.value
        } catch {
            err("下载整合包失败：\(error.localizedDescription)")
            hint("下载整合包失败：\(error.localizedDescription)", type: .critical)
            return
        }
        
        let index: ModrinthModpackIndex
        do {
            index = try viewModel.loadIndex(destination)
        } catch {
            err("加载整合包索引失败：\(error.localizedDescription)")
            hint("加载整合包索引失败：\(error.localizedDescription)", type: .critical)
            return
        }
        
        guard var name: String = await MessageBoxManager.shared.showInputAsync(
            title: "安装整合包 - 输入实例名",
            initialContent: index.name
        ) else { return }
        
        do {
            name = try repository.checkInstanceName(name)
        } catch {
            hint("该名称不可用：\(error.localizedDescription)", type: .critical)
            return
        }
        
        let installTask: MyTask<ModrinthModpackInstallTask.Model>
        do {
            installTask = try ModrinthModpackInstallTask.create(
                url: destination,
                index: index,
                repository: repository,
                name: name
            ) { instance in
                InstanceManager.shared.switchInstance(to: instance, repository)
            }
        } catch {
            err("创建安装任务失败：\(error.localizedDescription)")
            hint("创建安装任务失败：\(error.localizedDescription)", type: .critical)
            return
        }
        TaskManager.shared.execute(task: installTask)
    }
    
    @ViewBuilder
    private func versionCard(versionGroup: ResourceInstallViewModel.VersionGroup, isSelected: Bool = false, folded: Bool = true) -> some View {
        MyCard((isSelected ? "最佳版本：" : "") + versionGroup.0.description, folded: folded) {
            let dependencies: [ProjectVersionModel.Dependency] = versionGroup.1[0].requiredDependencies
            if !dependencies.isEmpty {
                VStack(alignment: .leading) {
                    MyText("前置资源")
                    VStack(spacing: 0) {
                        ForEach(dependencies) { dependency in
                            ProjectListItemView(project: dependency.project)
                                .onTapGesture {
                                    AppRouter.shared.append(.projectInstall(project: dependency.project))
                                }
                        }
                    }
                    MyText("版本列表")
                }
            }
            VStack(spacing: 0) {
                ForEach(versionGroup.1) { version in
                    VersionListItemView(version: version)
                        .onTapGesture {
                            log("\(version.name) \(version.version) 被点击")
                            Task {
                                do {
                                    if viewModel.project.type == .modpack {
                                        try await onModpackTap(version)
                                    } else {
                                        try await onVersionTap(version)
                                    }
                                } catch {
                                    err("执行点击回调意外失败：\(error.localizedDescription)")
                                    hint("执行点击回调意外失败：\(error.localizedDescription)", type: .critical)
                                }
                            }
                        }
                }
            }
        }
    }
    
    private struct VersionListItemView: View {
        private let model: ListItem
        
        init(version: ProjectVersionModel) {
            self.model = .init(
                image: "\(version.type.rawValue.capitalized)Block",
                name: version.name,
                description: "\(version.version)，更新于\(version.datePublished)，\(version.type.localizedName)"
            )
        }
        
        var body: some View {
            MyListItem(model)
        }
    }
}
