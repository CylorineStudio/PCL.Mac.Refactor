//
//  InstanceListSidebar.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/12/27.
//

import SwiftUI
import Core

struct InstanceListSidebar: Sidebar {
    @StateObject private var instanceVM: InstanceViewModel
    
    init(instanceManager: InstanceManager) {
        self._instanceVM = .init(wrappedValue: InstanceViewModel(instanceManager: instanceManager))
    }
    
    let width: CGFloat = 300
    private let modpackViewModel: ModpackViewModel = .init()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !instanceVM.repositories.isEmpty {
                MyText("目录列表", size: 12, color: .colorGray3)
                    .padding(.leading, 13)
                    .padding(.top, 18)
                MyNavigationList(
                    routeList: instanceVM.repositories.map { .init(AppRoute.instanceList(repositoryId: $0.id), nil, $0.name) }
                ) { route in
                    guard case .instanceList(let repositoryId) = route,
                          case .instanceList(let currentRepositoryId) = AppRouter.shared.last,
                          repositoryId == currentRepositoryId else { return }
                    instanceVM.reload(repository: instanceVM.currentRepository)
                }
            }
            MyText("添加或导入", size: 12, color: .colorGray3)
                .padding(.leading, 13)
                .padding(.top, 18)
            VStack(spacing: 0) {
                ImportButton(.iconAdd, "添加已有目录", perform: requestAddRepository)
                ImportButton(.iconImportModpack, "导入整合包", perform: onImportModpackClicked)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func requestAddRepository() {
        let panel: NSOpenPanel = .init()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        if panel.runModal() == .OK, let url = panel.url {
            if let repository = instanceVM.repositories.first(where: { $0.url == url }) {
                instanceVM.switchRepository(to: repository)
                AppRouter.shared.setRoot(.launch)
                AppRouter.shared.append(.instanceList(repositoryId: repository.id))
                return
            }
            MessageBoxManager.shared.showInput(
                title: "输入目录名",
                initialContent: url.lastPathComponent
            ) { name in
                if let name {
                    instanceVM.addRepository(name: name, url: url)
                }
            }
        }
    }
    
    private func onImportModpackClicked() {
        let repository = instanceVM.currentRepository
        
        let panel: NSOpenPanel = .init()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [
            .zip,
            .init(filenameExtension: "mrpack")!
        ]
        
        if panel.runModal() == .OK {
            guard let url = panel.url else { return }
            Task.detached {
                await importModpack(url, repository: repository)
            }
        }
    }
    
    private func importModpack(_ url: URL, repository: MinecraftRepository) async {
        do {
            guard let result: ModpackViewModel.ModpackLoadResult = try modpackViewModel.loadModpack(at: url) else {
                _ = await MessageBoxManager.shared.showTextAsync(
                    title: "不支持的整合包格式",
                    content: "很抱歉，PCL.Mac 目前只支持导入 Modrinth 格式的整合包，不支持这个整合包使用的格式……",
                    level: .error
                )
                return
            }
            guard await MessageBoxManager.shared.showTextAsync(
                title: "整合包信息",
                content: "格式：\(result.format)\n名称：\(result.name)\n版本：\(result.version)\n描述：\(result.summary)\n依赖：\(result.dependencyInfo)\n\n是否继续安装？",
                level: .info,
                .no(),
                .yes(label: "继续")
            ) == 1 else { return }
            
            guard var name: String = await MessageBoxManager.shared.showInputAsync(
                title: "导入整合包 - 输入实例名",
                initialContent: result.name
            ) else { return }
            
            do {
                name = try repository.checkInstanceName(name)
            } catch {
                hint("该名称不可用：\(error.localizedDescription)", type: .critical)
                return
            }
            
            switch result.index {
            case .modrinth(let index):
                let task = try ModrinthModpackInstallTask.create(
                    url: url,
                    index: index,
                    repository: repository,
                    name: name
                ) { instance in
                    instanceVM.switchInstance(to: instance, in: repository)
                    if AppRouter.shared.last == .tasks {
                        AppRouter.shared.removeLast()
                    }
                }
                
                TaskManager.shared.execute(task: task)
                AppRouter.shared.append(.tasks)
            }
        } catch {
            err("导入整合包失败：\(error)")
            hint("导入整合包失败：\(error.localizedDescription)", type: .critical)
        }
    }
}

private struct ImportButton: View {
    private let icon: ImageResource
    private let label: String
    private let perform: () throws -> Void
    
    public init(_ icon: ImageResource, _ label: String, perform: @escaping () throws -> Void) {
        self.icon = icon
        self.label = label
        self.perform = perform
    }
    
    var body: some View {
        MyListItem {
            HStack {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22)
                    .foregroundStyle(Color.color1)
                    .padding(.leading, 10)
                MyText(label)
                Spacer()
            }
            .padding(.vertical, 2)
        }
        .onTapGesture {
            try? perform()
        }
    }
}
