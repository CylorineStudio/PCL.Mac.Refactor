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
        VStack {
            if launchManager.launching {
                launchingBody
            } else {
                normalBody
            }
        }
    }
    
    @ViewBuilder
    private var normalBody: some View {
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
    
    @ViewBuilder
    private var launchingBody: some View {
        Spacer()
        if let currentStage: String = launchManager.currentStage {
            MyText("当前阶段：\(currentStage)")
        }
        MyText("进度：\(launchManager.progress)")
        Spacer()
        MyButton("取消", launchManager.cancel)
            .frame(height: 32)
            .padding(21)
    }
}
