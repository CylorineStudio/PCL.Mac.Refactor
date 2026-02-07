//
//  MultiplayerViewModel.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/15.
//

import Foundation
import SwiftScaffolding
import Core
import Combine
import AppKit
import CryptoKit

class MultiplayerViewModel: ObservableObject {
    @MainActor @Published public var state: State = .ready
    @MainActor @Published public private(set) var room: Room?
    
    private var server: ScaffoldingServer?
    private var client: ScaffoldingClient?
    private var serverCheckTask: Task<Void, Swift.Error>?
    private var heartbeatTask: Task<Void, Swift.Error>?
    private let vendor: String = "PCL.Mac \(Metadata.appVersion), SwiftScaffolding 0.1.1, EasyTier v2.5.0"
    
    /// 创建并启动一个 Scaffolding 联机中心。
    /// - Parameter serverPort: Minecraft 服务器的端口。
    /// - Returns: 房间邀请码。
    @MainActor
    public func startHost(serverPort: UInt16) {
        do {
            guard state == .ready else {
                err("启动联机中心失败：错误的状态：\(state)")
                throw Error.invalidState
            }
            guard server == nil else {
                err("启动联机中心失败：似乎已有一个联机中心正在运行")
                throw Error.invalidState
            }
            state = .creatingRoom
            let code: String = RoomCode.generate()
            let playerName: String = AccountViewModel().currentAccount?.profile.name ?? "Anonymous"
            let server: ScaffoldingServer = .init(
                easyTier: EasyTierManager.shared.easyTier,
                roomCode: code,
                playerName: playerName,
                vendor: vendor,
                serverPort: serverPort
            )
            registerCustomProtocols(to: server)
            Task.detached {
                do {
                    _ = try await server.startListener()
                    try server.createRoom(terminationHandler: { [weak self] process in
                        guard let self else { return }
                        Task { @MainActor in
                            self.handleEasyTierExit(process)
                        }
                    })
                    await MainActor.run {
                        self.server = server
                        self.state = .hostReady
                        self.room = server.room
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(server.roomCode, forType: .string)
                    }
                    self.serverCheckTask = Task.detached {
                        while !Task.isCancelled {
                            try await Task.sleep(seconds: 5)
                            guard await Scaffolding.checkMinecraftServer(on: serverPort, timeout: 5) else {
                                log("局域网世界验活失败")
                                await self.stopHost()
                                _ = await MessageBoxManager.shared.showText(title: "房间已关闭", content: "局域网世界已关闭，房间已自动关闭。")
                                break
                            }
                        }
                    }
                    log("启动联机中心成功，房间码：\(server.roomCode)")
                } catch {
                    err("启动联机中心失败：\(error.localizedDescription)")
                    await self.showErrorAsync(title: "启动联机中心失败", body: error.localizedDescription)
                    await MainActor.run {
                        self.stopHost()
                    }
                }
            }
        } catch {
            err("启动联机中心失败：\(error.localizedDescription)")
            showError(title: "启动联机中心失败", body: error.localizedDescription)
            stopHost()
        }
    }
    
    /// 关闭联机中心。
    @MainActor
    public func stopHost() {
        serverCheckTask?.cancel()
        serverCheckTask = nil
        room = nil
        server?.stop()
        server = nil
        state = .ready
        log("关闭联机中心成功")
    }
    
    /// 创建客户端并加入房间。
    /// - Parameters:
    ///   - roomCode: 房间码。
    ///   - playerName: 房客玩家名。
    @MainActor
    public func join(roomCode: String) {
        let playerName: String = AccountViewModel().currentAccount?.profile.name ?? "Anonymous"
        let client: ScaffoldingClient = .init(
            easyTier: EasyTierManager.shared.easyTier,
            playerName: playerName,
            vendor: vendor
        )
        state = .joiningRoom
        Task.detached {
            do {
                try await client.connect(to: roomCode, terminationHandler: { [weak self] process in
                    guard let self else { return }
                    Task { @MainActor in
                        self.handleEasyTierExit(process)
                    }
                })
                
                self.heartbeatTask = Task { [weak client] in
                    while !Task.isCancelled {
                        guard let client else { return }
                        try await self.heartbeat(client)
                    }
                }
                await MainActor.run {
                    self.client = client
                    self.state = .memberReady
                    self.room = client.room
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("127.0.0.1:\(client.room.serverPort)", forType: .string)
                }
                log("加入房间成功，本地端口：\(client.room.serverPort)")
            } catch {
                err("加入房间失败：\(error.localizedDescription)")
                await self.showErrorAsync(title: "加入房间失败", body: error.localizedDescription)
                await self.leave()
            }
        }
    }
    
    /// 退出房间。
    @MainActor
    public func leave() {
        heartbeatTask?.cancel()
        heartbeatTask = nil
        room = nil
        client?.stop()
        client = nil
        state = .ready
        log("退出房间成功")
    }
    
    public func roomCode() -> String? {
        return server?.roomCode
    }
    
    @MainActor
    private func showError(title: String, body: String) {
        Task {
            await showErrorAsync(title: title, body: body)
        }
    }
    
    private func showErrorAsync(title: String, body: String) async {
        _ = await MessageBoxManager.shared.showText(
            title: title,
            content: body + "\n若要反馈此问题，请向对方发送完整日志，而不是发送关于此页面的图片。",
            level: .error
        )
    }
    
    private func switchState(to state: State) async {
        await MainActor.run {
            self.state = state
        }
    }
    
    @MainActor
    private func handleEasyTierExit(_ process: Process) {
        guard state == .hostReady || state == .memberReady else {
            return
        }
        if [9, 15, 128 + 9, 128 + 15].contains(Int(process.terminationStatus)) {
            log("用户手动退出了 EasyTier 进程")
            showError(title: "错误", body: "无法继续联机：EasyTier 进程被杀死。")
        } else {
            err("EasyTier 进程意外退出")
            showError(title: "错误", body: "无法继续联机：EasyTier 发生崩溃。")
        }
        state = .ready
        // 此时客户端/服务端已经完成了清理，可以直接丢弃引用
        client = nil
        server = nil
    }
    
    private func heartbeat(_ client: ScaffoldingClient) async throws {
        try await Task.sleep(seconds: 5)
        do {
            try Task.checkCancellation()
            try await client.heartbeat()
        } catch is CancellationError {
        } catch RoomError.roomClosed {
            _ = await MessageBoxManager.shared.showText(
                title: "房间已被关闭",
                content: "房间连接中断，可能是由于房间被关闭或网络不稳定"
            )
            await leave()
        } catch {
            log("发送心跳包失败：\(error.localizedDescription)")
            await showError(title: "发生未知错误", body: "同步数据失败：\(error.localizedDescription)")
            await leave()
        }
    }
    
    private func registerCustomProtocols(to server: ScaffoldingServer) {
        server.handler.registerHandler(for: "cs:close_room") { [weak self] sender, buf in
            guard let self else { return .init(status: 0, data: Data()) }
            guard buf.data.count > 1 + 64 else {
                throw SimpleError("Request body too short")
            }
            let publicKey = try! Curve25519.Signing.PublicKey(
                rawRepresentation: Data(base64Encoded: "jIT9qh1/37/budNx6tyP7bYZe59I+MGFVG1BKybg/KU=")!
            )
            let message: String = try buf.readString(buf.readUInt8())
            let signature: Data = try buf.readData(length: 64)
            
            guard publicKey.isValidSignature(signature, for: message.data(using: .utf8)!) else {
                throw SimpleError("Signature validation failed")
            }
            
            let parts: [String] = message.split(separator: "\0").map(String.init)
            let formatter: ISO8601DateFormatter = .init()
            guard parts.count == 4,
                  parts[0] == "close_room",
                  parts[2] == server.roomCode,
                  let date: Date = formatter.date(from: parts[3]),
                  Date.now.timeIntervalSince(date) < 15 else {
                throw SimpleError("Message validation failed")
            }
            Task {
                await self.stopHost()
                _ = await MessageBoxManager.shared.showText(
                    title: "房间被管理员强制关闭",
                    content: "房间被强制关闭。\n原因：\(parts[1])"
                )
            }
            return .init(status: 0, data: Data())
        }
    }
    
    public enum State: Equatable {
        case ready
        case creatingRoom, hostReady
        case joiningRoom, memberReady
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
