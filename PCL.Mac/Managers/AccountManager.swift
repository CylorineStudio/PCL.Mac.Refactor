//
//  AccountManager.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/14.
//

import Foundation
import Core

class AccountManager: ObservableObject {
    public static let shared: AccountManager = .init()
    @Published public var accounts: [Account] = []
    
    /// 添加一个离线账号。
    /// - Parameters:
    ///   - name: 玩家名。
    ///   - uuid: 玩家的 `UUID`。若为 `nil`，则根据玩家名生成一个符合 Bukkit 行为的 `UUID`。
    public func addOffline(name: String, uuid: UUID? = nil) {
        accounts.append(OfflineAccount(name: name, uuid: uuid ?? UUIDUtils.uuid(ofOfflinePlayer: name)))
    }
    
    /// 添加一个微软账号。
    public func addMicrosoft(from response: MicrosoftAuthService.MinecraftAuthResponse) {
        accounts.append(MicrosoftAccount(profile: response.profile, accessToken: response.accessToken, refreshToken: response.refreshToken))
    }
    
    private init() {}
}
