//
//  AccountViewModel.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/15.
//

import Foundation
import Combine
import Core

class AccountViewModel: ObservableObject {
    @Published public private(set) var accounts: [Account] = [] {
        didSet {
            LauncherConfig.shared.accounts = accounts
        }
    }
    @Published public private(set) var currentAccountId: UUID? {
        didSet {
            LauncherConfig.shared.currentAccountId = currentAccountId
        }
    }
    public var currentAccount: Account? {
        if let currentAccountId {
            return accounts.first(where: { $0.id == currentAccountId })
        }
        return nil
    }
    
    public init() {
        self.accounts = LauncherConfig.shared.accounts
        self.currentAccountId = LauncherConfig.shared.currentAccountId
    }
    
    /// 检查待添加的离线账号的属性是否合法。
    /// - Parameters:
    ///   - name: 玩家名。
    ///   - uuid: 玩家 `UUID`。
    /// - Returns: 若合法，返回 `nil`，否则返回一个 `LocalizedError`。
    public func checkAttributes(name: String, uuid: String?) -> AccountError? {
        if let uuid, UUIDUtils.uuid(of: uuid) == nil {
            return .invalidUUID
        }
        if accounts.contains(where: { $0 is OfflineAccount && $0.profile.name == name }) {
            return .nameExists
        }
        return nil
    }
    
    /// 添加一个离线账号。
    /// - Parameters:
    ///   - name: 玩家名。
    ///   - uuid: 玩家 `UUID`。
    public func addOfflineAccount(name: String, uuid: String?) throws {
        if let error = checkAttributes(name: name, uuid: uuid) {
            log("离线账号检查不通过：\(error.localizedDescription)")
            throw error
        }
        let account: OfflineAccount = .init(name: name, uuid: try uuid.map(UUIDUtils.uuidThrowing(of:)) ?? UUIDUtils.uuid(ofOfflinePlayer: name))
        accounts.append(account)
        switchAccount(to: account)
    }
    
    /// 添加一个微软账号。
    /// - Parameter startCompletion: 设备码获取完成回调，此时需要用户打开 URL 并输入授权码。
    /// - Returns: 登录任务。
    public func addMicrosoftAccount(startCompletion: @escaping (MicrosoftAuthService.AuthorizationCode) -> Void) async throws -> MicrosoftAccount {
        log("开始进行微软登录")
        let service: MicrosoftAuthService = .init()
        let code = try await service.start()
        log("获取设备码成功")
        await MainActor.run {
            startCompletion(code)
        }
        
        guard let pollCount = service.pollCount,
              let pollInterval = service.pollInterval else {
            err("pollCount 或 pollInterval 未被设置")
            throw MicrosoftAuthService.Error.internalError
        }
        for _ in 0..<pollCount {
            try Task.checkCancellation()
            try await Task.sleep(seconds: Double(pollInterval))
            if try await service.poll() {
                break
            }
        }
        
        let response = try await service.authenticate()
        let account: MicrosoftAccount = .init(profile: response.profile, accessToken: response.accessToken, refreshToken: response.refreshToken)
        await MainActor.run {
            accounts.append(account)
            switchAccount(to: account)
        }
        return account
    }
    
    /// 切换当前账号。
    public func switchAccount(to account: Account) {
        currentAccountId = account.id
    }
}
