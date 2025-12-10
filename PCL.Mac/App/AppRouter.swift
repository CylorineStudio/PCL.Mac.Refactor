//
//  AppRouter.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/9.
//

import SwiftUI

enum AppRoute: Identifiable {
    case launch, download, multiplayer, settings, other, tasks
    // 下载页面的子页面
    case minecraftDownload, downloadPage2, downloadPage3
    
    var id: String { stringValue }
    
    var stringValue: String {
        switch self {
        default: String(describing: self)
        }
    }
}

class AppRouter: ObservableObject {
    static let shared: AppRouter = .init()
    
    @Published private(set) var path: [AppRoute] = [.launch]
    
    @ViewBuilder
    var content: some View {
        switch getLast() {
        case .launch:
            LaunchPage()
        case .minecraftDownload:
            MinecraftDownloadPage()
        case .downloadPage2:
            DownloadPage2()
        case .downloadPage3:
            DownloadPage3()
        case .tasks:
            TasksPage()
        default:
            Spacer()
        }
    }
    
    var sidebar: any Sidebar {
        switch getRoot() {
        case .launch:
            LaunchSidebar()
        case .download:
            DownloadSidebar()
        case .tasks:
            TasksSidebar()
        default:
            EmptySidebar()
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
    }
    
    func append(_ route: AppRoute) {
        path.append(route)
    }
    
    func removeLast() {
        if path.count > 1 {
            path.removeLast()
        }
    }
    
    private init() {
    }
}
