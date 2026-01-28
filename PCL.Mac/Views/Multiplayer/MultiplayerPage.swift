//
//  MultiplayerPage.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/15.
//

import SwiftUI
import SwiftScaffolding

struct MultiplayerPage: View {
    @EnvironmentObject private var viewModel: MultiplayerViewModel
    @StateObject private var loadingViewModel: MyLoadingViewModel = .init(text: "创建房间中")
    
    var body: some View {
        CardContainer {
            switch viewModel.state {
            case .ready: readyBody
            case .creatingRoom, .joiningRoom:
                MyLoading(viewModel: loadingViewModel)
            case .hostReady, .memberReady:
                multiplayerReadyView
            }
        }
        .onChange(of: viewModel.state) { newValue in
            if newValue == .creatingRoom {
                loadingViewModel.text = "创建房间中"
            } else if newValue == .joiningRoom {
                loadingViewModel.text = "加入房间中"
            }
        }
    }
    
    private var readyBody: some View {
        MyCard("开始联机", foldable: false) {
            VStack(spacing: 0) {
                MyListItem(.init(image: .init(named: "MultiplayerPageIcon"), imageSize: 28, name: "创建房间", description: "创建房间并生成邀请码，与好友一起畅玩"))
                    .onTapGesture {
                        if EasyTierManager.shared.hintInstall() {
                            return
                        }
                        viewModel.startHost(serverPort: 25565)
                    }
                MyListItem(.init(image: .init(named: "IconAdd"), imageSize: 28, name: "加入房间", description: "输入房主提供的邀请码，加入游戏世界"))
                    .onTapGesture {
                        if EasyTierManager.shared.hintInstall() {
                            return
                        }
                        Task {
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
                    PlayerListView(room: room)
                    MyCard("", titled: false, limitHeight: false) {
                        VStack(spacing: 0) {
                            if viewModel.state == .hostReady, let roomCode = viewModel.roomCode() {
                                ActionView("复制房间码") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(roomCode, forType: .string)
                                    hint("复制成功！", type: .finish)
                                }
                                ActionView("关闭房间", color: .red) {
                                    Task {
                                        if await MessageBoxManager.shared.showText(
                                            title: "警告",
                                            content: "你确定要关闭房间吗？\n这会让除了你以外的所有玩家退出游戏！",
                                            level: .error,
                                            .init(id: 1, label: "是", type: .red),
                                            .init(id: 0, label: "否", type: .normal)
                                        ) == 1 {
                                            viewModel.stopHost()
                                        }
                                    }
                                }
                            } else {
                                ActionView("复制地址") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString("127.0.0.1:\(room.serverPort)", forType: .string)
                                    hint("复制成功！", type: .finish)
                                }
                                ActionView("退出房间", color: .red) {
                                    viewModel.leave()
                                }
                            }
                            Spacer()
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .frame(width: 120)
                    .frame(maxHeight: .infinity)
                }
            }
        }
    }
}

private struct PlayerListView: View {
    @ObservedObject private var room: Room
    
    init(room: Room) {
        self.room = room
    }
    
    var body: some View {
        MyCard("玩家列表", foldable: false, limitHeight: false) {
            VStack(spacing: 0) {
                ForEach(room.members, id: \.machineId) { member in
                    MyListItem(.init(name: member.name, description: "[\(member.kind.localizedName)] \(member.vendor)"))
                }
            }
        }
    }
}

private struct ActionView: View {
//    private let imageName: String
    private let text: String
    private let color: Color
    private let onClick: () -> Void
    
    init(_ text: String, color: Color = .color1, onClick: @escaping () -> Void) {
//        self.imageName = imageName
        self.text = text
        self.color = color
        self.onClick = onClick
    }
    
    var body: some View {
        MyListItem {
            HStack {
//                Image(imageName)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 16, height: 16)
                MyText(text, color: color)
                Spacer(minLength: 0)
            }
            .padding(2)
        }
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
