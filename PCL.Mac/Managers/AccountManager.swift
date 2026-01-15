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
    
    public func addOffline(name: String, uuid: UUID? = nil) {
        accounts.append(OfflineAccount(name: name, uuid: uuid ?? UUIDUtils.uuid(ofOfflinePlayer: name)))
    }
    
    public func addMicrosoft(from response: MicrosoftAuthService.MinecraftAuthResponse) {
        accounts.append(MicrosoftAccount(profile: response.profile, accessToken: response.accessToken, refreshToken: response.refreshToken))
    }
    
    private init() {}
}
