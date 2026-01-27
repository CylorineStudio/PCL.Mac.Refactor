//
//  MultiplayerViewModel.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/15.
//

import Foundation
import SwiftScaffolding
import Core

class MultiplayerViewModel: ObservableObject {
    @Published public var state: State = .ready
    private var server: ScaffoldingServer?
    private var client: ScaffoldingClient?
    private var heartbeatTask: Task<Void, Swift.Error>?
    private let vendor: String = "PCL.Mac \(Metadata.appVersion), SwiftScaffolding DEV, EasyTier v2.5.0"
    
    /// 创建并启动一个 Scaffolding 联机中心。
    /// - Parameter serverPort: Minecraft 服务器的端口。
    /// - Returns: 房间邀请码。
    public func startHost(serverPort: UInt16) {
        Task {
            do {
                guard state == .ready else {
                    err("启动联机中心失败：错误的状态：\(state)")
                    throw Error.invalidState
                }
                guard server == nil else {
                    err("启动联机中心失败：似乎已有一个联机中心正在运行")
                    throw Error.invalidState
                }
                await switchState(to: .creatingRoom)
                let code: String = RoomCode.generate()
                let server: ScaffoldingServer = .init(
                    easyTier: EasyTierManager.shared.easyTier,
                    roomCode: code,
                    playerName: "Test",
                    vendor: vendor,
                    serverPort: serverPort
                )
                
                do {
                    try await server.startListener()
                    try server.createRoom(terminationHandler: handleEasyTierExit(_:))
                    await MainActor.run {
                        self.server = server
                        self.state = .hostReady(roomCode: server.roomCode)
                    }
                    log("启动联机中心成功，房间码：\(server.roomCode)")
                } catch {
                    throw Error.startServerFailed(message: error.localizedDescription)
                }
            } catch {
                err("启动联机中心失败：\(error.localizedDescription)")
                await showError(title: "启动联机中心失败", body: error.localizedDescription)
                await MainActor.run {
                    stopHost()
                }
            }
        }
    }
    
    /// 关闭联机中心。
    public func stopHost() {
        server?.stop()
        server = nil
        state = .ready
        log("关闭联机中心成功")
    }
    
    /// 创建客户端并加入房间。
    /// - Parameters:
    ///   - roomCode: 房间码。
    ///   - playerName: 房客玩家名。
    public func join(roomCode: String, playerName: String) {
        Task {
            do {
                let client: ScaffoldingClient = .init(
                    easyTier: EasyTierManager.shared.easyTier,
                    playerName: playerName,
                    vendor: vendor,
                    roomCode: roomCode
                )
                await switchState(to: .joiningRoom)
                try await client.connect(terminationHandler: handleEasyTierExit(_:))
                self.heartbeatTask = Task {
                    while true {
                        try await Task.sleep(seconds: 5)
                        try await client.heartbeat()
                    }
                }
                self.client = client
                await switchState(to: .memberReady(address: "127.0.0.1:\(client.room.serverPort)"))
            } catch {
                err("加入房间失败：\(error.localizedDescription)")
                await showError(title: "加入房间失败", body: error.localizedDescription)
                await MainActor.run {
                    leave()
                }
            }
        }
    }
    
    /// 退出房间。
    public func leave() {
        heartbeatTask?.cancel()
        heartbeatTask = nil
        client?.stop()
        client = nil
        state = .ready
        log("退出房间成功")
    }
    
    private func showError(title: String, body: String) async {
        _ = await MessageBoxManager.shared.showText(
            title: title,
            content: body + "\n若要反馈此问题，请向对方发送完整日志，而不是发送此页面的图片。",
            level: .error
        )
    }
    
    private func switchState(to state: State) async {
        await MainActor.run {
            self.state = state
        }
    }
    
    private func handleEasyTierExit(_ process: Process) {
        switch state {
        case .hostReady(_), .memberReady(_):
            Task {
                if [128 + SIGTERM, 128 + SIGKILL].contains(process.terminationStatus) {
                    log("用户手动退出了 EasyTier 进程")
                    await showError(title: "错误", body: "无法继续联机：EasyTier 进程被杀死。")
                } else {
                    err("EasyTier 进程意外退出")
                    await showError(title: "错误", body: "无法继续联机：EasyTier 发生崩溃。")
                }
                await MainActor.run {
                    state = .ready
                    // 此时客户端/服务端已经完成了清理，可以直接丢弃引用
                    client = nil
                    server = nil
                }
            }
        default: return
        }
    }
    
    public enum State: Equatable {
        case ready
        
        case searchingMinecraft, creatingRoom, hostReady(roomCode: String)
        case joiningRoom, memberReady(address: String)
    }
    
    public enum Error: LocalizedError {
        case invalidState
        case startServerFailed(message: String)
        
        public var errorDescription: String? {
            switch self {
            case .invalidState: "错误的状态。"
            case .startServerFailed(let message): message
            }
        }
    }
}
