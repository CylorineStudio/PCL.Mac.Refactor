//
//  LaunchSidebar.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/10.
//

import SwiftUI
import Core

struct LaunchSidebar: Sidebar {
    @EnvironmentObject private var instanceViewModel: InstanceViewModel
    @ObservedObject private var launchManager: MinecraftLaunchManager = .shared
    @StateObject private var accountViewModel: AccountViewModel = .init()
    @State private var showingAccountEditor: Bool = false
    @State private var accountEditAppeared: Bool = false
    
    let width: CGFloat = 285
    
    var body: some View {
        if launchManager.isLaunching {
            launchingBody
        } else {
            normalBody
        }
    }
    
    private var normalBody: some View {
        VStack {
            Spacer()
            if showingAccountEditor {
                accountEditorView
                    .opacity(accountEditAppeared ? 1 : 0)
                    .scaleEffect(accountEditAppeared ? 1 : 0.95)
                    .animation(.spring(response: 0.2), value: accountEditAppeared)
                    .onAppear {
                        accountEditAppeared = true
                    }
            } else if let account = accountViewModel.currentAccount {
                MyListItem {
                    VStack(spacing: 15) {
                        PlayerAvatar(account)
                        MyText(account.profile.name, size: 16)
                    }
                }
                .fixedSize()
                .onTapGesture {
                    showingAccountEditor = true
                }
            }
            Spacer()
            VStack(spacing: 11) {
                Group {
                    if let instance = instanceViewModel.currentInstance,
                       let repository = instanceViewModel.currentRepository {
                        MyButton("启动游戏", subLabel: instance.name, type: .highlight) {
                            guard !launchManager.isRunning && !launchManager.isLaunching else {
                                hint("已有一个游戏实例正在运行！", type: .critical)
                                return
                            }
                            if let account: Account = accountViewModel.currentAccount {
                                instanceViewModel.launch(instance, account, in: repository)
                            } else {
                                hint("你还没有添加账号！", type: .critical)
                            }
                        }
                    } else {
                        MyButton("下载游戏", subLabel: "未找到可用的游戏实例", type: .normal) {
                            AppRouter.shared.setRoot(.download)
                        }
                    }
                }
                .frame(height: 50)
                HStack(spacing: 11) {
                    MyButton("实例选择") {
                        if let repository: MinecraftRepository = instanceViewModel.currentRepository {
                            AppRouter.shared.append(.instanceList(repository))
                        } else {
                            AppRouter.shared.append(.noInstanceRepository)
                        }
                    }
                    if let instance = instanceViewModel.currentInstance {
                        MyButton("实例设置") {
                            AppRouter.shared.append(.instanceSettings(id: instance.name))
                        }
                    }
                }
                .frame(height: 32)
            }
            .padding(21)
            .onAppear {
                if accountViewModel.currentAccount == nil { showingAccountEditor = true }
            }
        }
    }
    
    private func hideAccountEditor() {
        accountEditAppeared = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showingAccountEditor = false
        }
    }
    
    private var accountEditorView: some View {
        VStack {
            accountList
                .padding(.horizontal, 8)
            HStack {
                MyButton("添加账号") {
                    accountViewModel.requestAddAccount()
                }
                .frame(width: 80)
                
                if accountViewModel.currentAccount != nil {
                    MyButton("返回") {
                        hideAccountEditor()
                    }
                    .frame(width: 50)
                }
            }
            .frame(height: 30)
        }
    }
    
    private var accountList: some View {
        VStack(spacing: 0) {
            ForEach(accountViewModel.accounts, id: \.id) { account in
                MyListItem { hovered in
                    HStack {
                        if account.id == accountViewModel.currentAccount?.id {
                            RightRoundedRectangle(cornerRadius: 4)
                                .fill(Color.color3)
                                .frame(width: 4, height: 20)
                                .offset(x: -4)
                        } else {
                            Spacer()
                                .frame(width: 12)
                        }
                        PlayerAvatar(account, length: 36)
                        VStack(alignment: .leading) {
                            MyText(account.profile.name)
                            MyText(account.type.localized, color: .colorGray3)
                        }
                        Spacer()
                        if hovered {
                            Image(systemName: "trash")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12)
                                .foregroundStyle(Color.color3)
                                .padding(.trailing, 8)
                                .contentShape(.rect)
                                .onTapGesture {
                                    accountViewModel.remove(account: account)
                                    hint("移除成功！", type: .finish)
                                }
                        }
                    }
                }
                .onTapGesture {
                    accountViewModel.switchAccount(to: account)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: accountViewModel.currentAccount?.id)
    }
    
    private var launchingBody: some View {
        VStack(spacing: 0) {
            Spacer()
            MyLoading(viewModel: launchManager.loadingModel, showCard: false)
            if let instanceName = launchManager.instanceName {
                MyText(instanceName, size: 13.5, color: .color3)
                    .padding(.top, 5)
            }
            HStack(spacing: 0) {
                Rectangle()
                    .fill(
                        LinearGradient(stops: [
                            .init(color: Color.color4, location: 0),
                            .init(color: Color.color3, location: 0.6)
                        ], startPoint: .topLeading, endPoint: .topTrailing)
                    )
                    .frame(width: 225 * launchManager.progress)
                Rectangle()
                    .fill(Color.color6)
                    .opacity(0.6)
            }
            .frame(width: 225, height: 4)
            .padding(.top, 12)
            .padding(.bottom, 27)
            
            // PanLaunchingInfo
            VStack(alignment: .leading) {
                if let currentStage: String = launchManager.currentStage {
                    launchingInfo(name: "当前步骤", value: currentStage)
                }
                launchingInfo(name: "启动进度") {
                    AnimatablePercentText(progress: launchManager.progress)
                }
            }
            
            // PanLaunchingHint
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.colorGray1, lineWidth: 1)
                    .padding(1)
                HStack {
                    MyText("你知道吗", size: 12.5)
                        .opacity(0.5)
                        .padding(.horizontal, 10)
                        .background(.white)
                        .offset(y: -8)
                }
                MyText("这是一段测试用的小提示文本，它应该足够长以让它有两行。", size: 12.5)
                    .padding(11)
            }
            .frame(width: 260, height: launchManager.isRunning ? nil : 0)
            .opacity(launchManager.isRunning ? 1 : 0)
            .padding(.top, 26)
            .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            MyButton("取消", launchManager.cancel)
                .frame(height: 32)
                .padding(21)
        }
        .animation(.easeOut(duration: 0.2), value: launchManager.progress)
        .animation(.easeOut(duration: 0.1), value: launchManager.isRunning)
    }
    
    @ViewBuilder
    private func launchingInfo(name: String, value: String) -> some View {
        launchingInfo(name: name) { MyText(value, size: 12.5) }
    }
    
    @ViewBuilder
    private func launchingInfo(name: String, value: () -> some View) -> some View {
        HStack(spacing: 15) {
            MyText(name, size: 12.5)
                .opacity(0.5)
            value()
        }
    }
}

private struct AnimatablePercentText: View, Animatable {
    var progress: Double
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    var body: some View {
        let clamped: Double = min(max(progress, 0), 1)
        MyText(String(format: "%.2f %%", clamped * 100), size: 12.5)
    }
}
