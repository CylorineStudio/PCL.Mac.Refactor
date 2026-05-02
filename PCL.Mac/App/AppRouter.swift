//
//  AppRouter.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/11/9.
//

import SwiftUI
import Core

enum AppRoute: Identifiable, Hashable, Equatable {
    // 根页面
    case launch, download, multiplayer, settings, more, tasks
    
    // 启动页面的子页面
    case instanceList(repositoryId: UUID), instanceSettings(id: String)
    
    // 实例设置页面的子页面
    case instanceConfig(id: String)
    
    // 下载页面的子页面
    case minecraftDownload, minecraftInstallOptions(version: VersionManifest.Version), modDownload, resourcepackDownload, shaderpackDownload, modpackDownload
    case projectInstall(project: ProjectListItemModel)
    
    // 联机页面的子页面
    case multiplayerSub, multiplayerSettings
    
    // 设置页面的子页面
    case javaSettings, otherSettings
    
    // 更多页面的子页面
    case about, toolbox
    
    var id: String { stringValue }
    
    var stringValue: String {
        switch self {
        default: String(describing: self)
        }
    }
}

@MainActor
class AppRouter: ObservableObject {
    static let shared: AppRouter = .init()
    private static let rootRoutes: [AppRoute] = [.launch, .download, .multiplayer, .settings, .more]
    
    @Published private(set) var path: [AppRoute] = [.launch]
    
    /// 当前子页面的标题
    var title: String {
        switch last {
        case .tasks: "任务列表"
        case .instanceList: "实例列表"
        case .instanceSettings(let id), .instanceConfig(let id): "实例设置 - \(id)"
        case .minecraftInstallOptions(let version): "游戏安装 - \(version.id)"
        case .projectInstall(let project): "资源下载 - \(project.title)"
        default: "错误：当前页面没有标题，请报告此问题！"
        }
    }
    
    /// 当前页面是不是子页面（需要显示返回键和标题，隐藏导航按钮）
    var isSubPage: Bool {
        switch last {
        case .tasks: true
        case .instanceList: true
        case .instanceSettings, .instanceConfig: true
        case .minecraftInstallOptions: true
        case .projectInstall: true
        default: false
        }
    }
    
    var last: AppRoute { path[path.count - 1] }
    var root: AppRoute { path[0] }
    
    func setRoot(_ newRoot: AppRoute) {
        path = [newRoot]
        // 各根页面的默认子页面
        if newRoot == .download { append(.minecraftDownload) }
        if newRoot == .multiplayer { append(.multiplayerSub) }
        if newRoot == .settings { append(.javaSettings) }
        if newRoot == .more { append(.about) }
    }
    
    func append(_ route: AppRoute) {
        path.append(route)
        if case .instanceSettings(let id) = route { append(.instanceConfig(id: id)) }
    }
    
    func removeLast() {
        if path.count > 1 {
            path.removeLast()
            if case .instanceSettings = last { removeLast() }
        }
    }
    
    private init() {}
}

struct AppRouterView: View {
    @ObservedObject private var router: AppRouter = .shared
    @EnvironmentObject private var instanceManager: InstanceManager
    
    var body: some View {
        switch router.last {
        case .launch:
            LaunchPage()
        case .minecraftDownload:
            MinecraftDownloadPage()
        case .minecraftInstallOptions(let version):
            MinecraftInstallOptionsPage(instanceManager: instanceManager, version: version)
        case .modDownload:
            ResourcesSearchPage(type: .mod)
        case .resourcepackDownload:
            ResourcesSearchPage(type: .resourcepack)
        case .shaderpackDownload:
            ResourcesSearchPage(type: .shader)
        case .modpackDownload:
            ResourcesSearchPage(type: .modpack)
        case .projectInstall(let project):
            ResourceInstallPage(instanceManager: instanceManager, project: project)
                .id(project)
        case .tasks:
            TasksPage()
        case .instanceList(let repositoryId):
            InstanceListPage(instanceManager: instanceManager, repositoryId: repositoryId)
                .id(repositoryId)
        case .multiplayerSub:
            MultiplayerPage()
        case .multiplayerSettings:
            MultiplayerSettingsPage()
        case .javaSettings:
            JavaSettingsPage()
        case .otherSettings:
            OtherSettingsPage()
        case .about:
            AboutPage()
        case .toolbox:
            ToolboxPage()
        case .instanceConfig(let id):
            InstanceConfigPage(instanceManager: instanceManager, id: id)
        default:
            Spacer()
        }
    }
}

struct AppSidebarView: View {
    @EnvironmentObject private var instanceManager: InstanceManager
    @ObservedObject private var router: AppRouter = .shared
    @State private var width: CGFloat = 0
    @State private var animationProgress: Double = 0
    
    init() {}
    
    var sidebar: any Sidebar {
        switch router.last {
        case .launch: LaunchSidebar(instanceManager: instanceManager)
        case .instanceList: InstanceListSidebar(instanceManager: instanceManager)
        case .instanceSettings(let id), .instanceConfig(let id): InstanceSettingsSidebar(id: id)
        case .minecraftDownload, .modDownload, .resourcepackDownload, .shaderpackDownload, .modpackDownload: DownloadSidebar()
        case .multiplayer, .multiplayerSub, .multiplayerSettings: MultiplayerSidebar()
        case .settings, .javaSettings, .otherSettings: SettingsSidebar()
        case .more, .about, .toolbox: MoreSidebar()
        case .tasks: TasksSidebar()
        default: EmptySidebar()
        }
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(.white)
                .frame(width: width)
                .shadow(radius: 2)
                .zIndex(10)
            
            AnyView(sidebar)
                .opacity(animationProgress)
                .scaleEffect(animationProgress * 0.04 + 0.96)
                .zIndex(11)
                .frame(width: sidebar.width)
        }
        .onAppear {
            width = sidebar.width
            // 当前一定是启动页面，直接开始动画
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                animationProgress = 1.0
            }
        }
        .onChange(of: sidebar.width) { newWidth in
            withAnimation(.spring(response: 0.16, dampingFraction: 1.0)) {
                width = newWidth
            }
            switch router.last {
            case .launch, .tasks:
                animationProgress = 0.0
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    animationProgress = 1.0
                }
            default:
                break
            }
        }
    }
}
