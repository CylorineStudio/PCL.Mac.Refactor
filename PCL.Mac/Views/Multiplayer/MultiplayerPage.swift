//
//  MultiplayerPage.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/15.
//

import SwiftUI
import SwiftScaffolding
import Core

struct MultiplayerPage: View {
    @EnvironmentObject private var viewModel: MultiplayerViewModel
    @StateObject private var loadingViewModel: MyLoadingViewModel = .init(text: "创建房间中")
    @State private var isEasyTierInstalled: Bool = true
    
    var body: some View {
        CardContainer {
            switch viewModel.state {
            case .ready:
                if isEasyTierInstalled {
                    readyBody
                } else {
                    installEasyTierBody
                }
            case .creatingRoom, .joiningRoom:
                MyLoading(viewModel: loadingViewModel)
            case .hostReady, .memberReady:
                multiplayerReadyView
            }
        }
        .onAppear {
            isEasyTierInstalled = EasyTierManager.shared.isInstalled()
        }
        .onChange(of: viewModel.state) { newValue in
            if newValue == .creatingRoom {
                loadingViewModel.text = "创建房间中"
            } else if newValue == .joiningRoom {
                loadingViewModel.text = "加入房间中"
            }
        }
    }
    
    private var installEasyTierBody: some View {
        MyCard("安装 EasyTier", foldable: false) {
            MyListItem(.init(image: .init(named: "DownloadPageIcon"), imageSize: 28, name: "安装 EasyTier", description: "联机功能使用 EasyTier 实现，所以你需要先安装 EasyTier 才能进行联机！"))
                .onTapGesture {
                    Task {
                        try await checkDisclaimer()
                        let task: MyTask = EasyTierManager.shared.makeInstallTask()
                        await MainActor.run {
                            TaskManager.shared.execute(task: task)
                            AppRouter.shared.append(.tasks)
                        }
                    }
                }
        }
    }
    
    private var readyBody: some View {
        MyCard("开始联机", foldable: false) {
            VStack(spacing: 0) {
                MyListItem(.init(image: .init(named: "MultiplayerPageIcon"), imageSize: 28, name: "创建房间", description: "使用局域网世界创建房间，并邀请好友加入！"))
                    .onTapGesture {
                        Task {
                            if await EasyTierManager.shared.hintInstall() {
                                return
                            }
                            try await checkDisclaimer()
                            guard await MessageBoxManager.shared.showText(
                                title: "开启房间",
                                content: "请按照以下步骤操作：\n   1. 进入世界，按下 ESC\n    2. 点击 “对局域网开放” > “创建局域网世界”\n    3. 回到启动器，点击 “确定” 并输入聊天栏中的端口号",
                                .init(id: 0, label: "取消", type: .normal),
                                .init(id: 1, label: "确定", type: .highlight)
                            ) == 1 else { return }
                            guard let rawPort: String = await MessageBoxManager.shared.showInput(title: "输入端口号") else {
                                return
                            }
                            guard let port: UInt16 = .init(rawPort), await Scaffolding.checkMinecraftServer(on: port, timeout: 1) else {
                                hint("无效的端口号！", type: .critical)
                                return
                            }
                            viewModel.startHost(serverPort: port)
                        }
                    }
                MyListItem(.init(image: .init(named: "IconAdd"), imageSize: 28, name: "加入房间", description: "通过房主分享的房间码，加入游戏世界！"))
                    .onTapGesture {
                        Task {
                            if await EasyTierManager.shared.hintInstall() {
                                return
                            }
                            try await checkDisclaimer()
                            if let type: AccountWrapper.AccountType = AccountViewModel().currentAccount?.type(),
                               type == .offline {
                                guard await MessageBoxManager.shared.showText(
                                    title: "警告",
                                    content: "你正在使用离线账号，可能会导致无法加入游戏！\n如果房主安装了 LAN Server Properties 等模组，可以忽略此警告。\n如果你拥有正版账号，请返回主页面并切换为正版账号。\n\n如果出现了“无效会话”等错误，请不要反馈给他人！",
                                    level: .error,
                                    .init(id: 0, label: "取消", type: .normal),
                                    .init(id: 1, label: "继续", type: .red)
                                ) == 1 else { return }
                            }
                            
                            if let roomCode: String = await MessageBoxManager.shared.showInput(title: "输入房间码", placeholder: "U/XXXX-XXXX-XXXX-XXXX") {
                                if RoomCode.isValid(code: roomCode) {
                                    viewModel.join(roomCode: roomCode)
                                } else {
                                    hint("错误的邀请码格式！", type: .critical)
                                }
                            }
                        }
                    }
            }
        }
    }
    
    @ViewBuilder
    private var multiplayerReadyView: some View {
        if let room = viewModel.room {
            VStack(spacing: 20) {
                MyCard("提示", foldable: false) {
                    VStack(alignment: .leading) {
                        if viewModel.state == .hostReady, let roomCode = viewModel.roomCode() {
                            MyText("房间码：\(roomCode)（已自动复制）")
                            MyText("你的好友可以通过这个房间码来加入房间！")
                        } else {
                            MyText("本地地址：127.0.0.1:\(room.serverPort)（已自动复制）")
                            MyText("你可以在游戏中点击 “多人游戏” > “直接连接”，然后输入这个地址来加入游戏！")
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack(alignment: .top, spacing: 20) {
                    MyCard("操作", foldable: false, limitHeight: false) {
                        VStack(spacing: 0) {
                            if viewModel.state == .hostReady, let roomCode = viewModel.roomCode() {
                                ActionView("IconCopy", "复制房间码") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(roomCode, forType: .string)
                                    hint("复制成功！", type: .finish)
                                }
                                ActionView("IconExit", "关闭房间", color: .red) {
                                    Task {
                                        if room.members.count > 1 {
                                            if await MessageBoxManager.shared.showText(
                                                title: "警告",
                                                content: "你确定要关闭房间吗？\n这会让除了你以外的所有玩家退出游戏！",
                                                level: .error,
                                                .init(id: 1, label: "是", type: .red),
                                                .init(id: 0, label: "否", type: .normal)
                                            ) != 1 { return }
                                        }
                                        viewModel.stopHost()
                                    }
                                }
                            } else {
                                ActionView("IconCopy", "复制地址") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString("127.0.0.1:\(room.serverPort)", forType: .string)
                                    hint("复制成功！", type: .finish)
                                }
                                ActionView("IconExit", "退出房间", color: .red) {
                                    viewModel.leave()
                                }
                            }
                            Spacer()
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(maxHeight: .infinity)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    PlayerListView(room: room)
                        .frame(maxHeight: .infinity)
                }
            }
        }
    }
    
    private func checkDisclaimer() async throws {
        if LauncherConfig.shared.multiplayerDisclaimerAgreed { return }
        if await MessageBoxManager.shared.showText(
            title: "免责声明",
            content: "在多人联机过程中，您须严格遵守所在国家和地区的相关法律法规。因违法使用本功能导致的后果将由用户自行承担。\n\n点击“同意”即表示您已阅读并同意上述全部内容。",
            level: .info,
            .init(id: 0, label: "不同意", type: .red),
            .init(id: 1, label: "同意", type: .highlight)
        ) == 0 {
            AppRouter.shared.setRoot(.launch)
            throw SimpleError("用户未同意免责声明")
        }
        LauncherConfig.shared.multiplayerDisclaimerAgreed = true
    }
}

private struct PlayerListView: View {
    @ObservedObject private var room: Room
    
    init(room: Room) {
        self.room = room
    }
    
    var body: some View {
        MyCard("玩家列表", foldable: false, limitHeight: false) {
            LazyVStack(spacing: 0) {
                ForEach(room.members, id: \.machineId) { member in
                    MyListItem(.init(name: member.name, description: "[\(member.kind.localizedName)] \(member.vendor)"))
                }
                Spacer(minLength: 0)
            }
        }
    }
}

private struct ActionView: View {
    private let imageName: String
    private let text: String
    private let color: Color
    private let onClick: () -> Void
    
    init(_ imageName: String, _ text: String, color: Color = .color1, onClick: @escaping () -> Void) {
        self.imageName = imageName
        self.text = text
        self.color = color
        self.onClick = onClick
    }
    
    var body: some View {
        MyListItem {
            HStack(spacing: 7) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(color)
                MyText(text, color: color)
                Spacer(minLength: 0)
            }
            .padding(2)
        }
        .frame(height: 27)
        .onTapGesture(perform: onClick)
    }
}

extension Member.Kind {
    var localizedName: String {
        switch self {
        case .host: "房主"
        case .guest: "成员"
        }
    }
}
