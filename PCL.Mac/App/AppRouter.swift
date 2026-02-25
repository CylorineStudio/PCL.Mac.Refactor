//
//  AppRouter.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/9.
//

import SwiftUI
import Core

enum AppRoute: Identifiable, Hashable, Equatable {
    // 根页面
    case launch, download, multiplayer, settings, more, tasks
    
    // 启动页面的子页面
    case instanceList(MinecraftRepository), noInstanceRepository, instanceSettings(id: String)
    
    // 实例设置页面的子页面
    case instanceConfig(id: String)
    
    // 下载页面的子页面
    case minecraftDownload, minecraftInstallOptions(version: VersionManifest.Version), downloadPage2, downloadPage3
    
    // 联机页面的子页面
    case multiplayerSub, multiplayerSettings
    
    // 更多页面的子页面
    case about
    
    var id: String { stringValue }
    
    var stringValue: String {
        switch self {
        default: String(describing: self)
        }
    }
}

class AppRouter: ObservableObject {
    static let shared: AppRouter = .init()
    private static let rootRoutes: [AppRoute] = [.launch, .download, .multiplayer, .settings, .more]
    
    @Published private(set) var path: [AppRoute] = [.launch]
    
    /// 当前页面的主内容（右半部分）
    @ViewBuilder
    var content: some View {
        switch getLast() {
        case .launch:
            LaunchPage()
        case .minecraftDownload:
            MinecraftDownloadPage()
        case .minecraftInstallOptions(let version):
            MinecraftInstallOptionsPage(version: version)
        case .downloadPage2:
            DownloadPage2()
        case .downloadPage3:
            DownloadPage3()
        case .tasks:
            TasksPage()
        case .instanceList(let repository):
            InstanceListPage(repository: repository)
        case .noInstanceRepository:
            NoInstanceRepositoryPage()
        case .multiplayerSub:
            MultiplayerPage()
        case .multiplayerSettings:
            MultiplayerSettingsPage()
        case .about:
            AboutPage()
        case .instanceConfig(let id):
            InstanceConfigPage(id: id)
        default:
            Spacer()
        }
    }
    
    /// 当前页面的侧边栏（左半部分）
    var sidebar: any Sidebar {
        switch getLast() {
        case .launch: LaunchSidebar()
        case .instanceList, .noInstanceRepository: InstanceListSidebar()
        case .instanceSettings(let id), .instanceConfig(let id): InstanceSettingsSidebar(id: id)
        case .minecraftDownload, .downloadPage2, .downloadPage3: DownloadSidebar()
        case .multiplayer, .multiplayerSub, .multiplayerSettings: MultiplayerSidebar()
        case .more, .about: MoreSidebar()
        case .tasks: TasksSidebar()
        default: EmptySidebar()
        }
    }
    
    /// 当前页面是不是子页面（需要显示返回键和标题，隐藏导航按钮）
    var isSubPage: Bool {
        switch getLast() {
        case .tasks: return true
        case .instanceList, .noInstanceRepository: return true
        case .instanceSettings, .instanceConfig: return true
        case .minecraftInstallOptions: return true
        default: return false
        }
    }
    
    /// 当前子页面的标题
    var title: String {
        switch getLast() {
        case .tasks: "任务列表"
        case .instanceList, .noInstanceRepository: "实例列表"
        case .instanceSettings(let id), .instanceConfig(let id): "实例设置 - \(id)"
        case .minecraftInstallOptions(let version): "游戏安装 - \(version.id)"
        default: "错误：当前页面没有标题，请报告此问题！"
        }
    }
    
    func getLast() -> AppRoute {
        return path[path.count - 1]
    }
    
    func getRoot() -> AppRoute {
        return path[0]
    }
    
    func setRoot(_ newRoot: AppRoute) {
        path = [newRoot]
        // 各根页面的默认子页面
        if newRoot == .download { append(.minecraftDownload) }
        if newRoot == .more { append(.about) }
        if newRoot == .multiplayer { append(.multiplayerSub) }
    }
    
    func append(_ route: AppRoute) {
        path.append(route)
        if case .instanceSettings(let id) = route { append(.instanceConfig(id: id)) }
    }
    
    func removeLast() {
        if path.count > 1 {
            path.removeLast()
            if case .instanceSettings = getLast() { removeLast() }
        }
    }
    
    private init() {}
}
