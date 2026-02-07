//
//  AccountViewModel.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/15.
//

import SwiftUI
import Combine
import Core
import SwiftyJSON

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
    
    /// 请求用户添加账号。
    public func requestAddAccount() {
        Task {
            log("开始请求添加账号")
            guard let idx: Int = await MessageBoxManager.shared.showList(
                title: "选择账号类型",
                items: [
                    .init(image: "IconMicrosoftAccount", imageSize: 32, name: "正版账号", description: nil),
                    .init(image: "IconOfflineAccount", imageSize: 32, name: "离线账号", description: nil)
                ]
            ) else {
                log("用户取消了添加")
                return
            }
            if idx == 0 {
                log("用户选择了添加正版账号")
                await requestAddMicrosoftAccount()
            } else {
                log("用户选择了添加离线账号")
                await requestAddOfflineAccount()
            }
        }
    }
    
    /// 切换当前账号。
    public func switchAccount(to account: Account) {
        currentAccountId = account.id
    }
    
    /// 移除账号。
    /// - Parameter account: 要移除的账号。
    public func remove(account: Account) {
        accounts.removeAll(where: { $0.id == account.id })
        if currentAccount == nil {
            if let firstAccount = accounts.first {
                switchAccount(to: firstAccount)
            } else {
                currentAccountId = nil
            }
        }
    }
    
    /// 获取账号皮肤数据。
    public func skinData(for account: Account) async -> Data {
        let defaultSkin: Data = .init(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAdVBMVEUAAAAKvLwAzMwmGgokGAgrHg0zJBE/KhW3g2uzeV5SPYn///+qclmbY0mQWT8Af38AaGhVVVWUYD52SzOBUzmPXj5JJRBCHQp3QjVqQDA0JRIoKCg3Nzc/Pz9KSko6MYlBNZtGOqUDenoFiIgElZUApKQAr6/wvakZAAAAAXRSTlMAQObYZgAAAolJREFUeNrt1l1rHucZReFrj/whu5hSCCQtlOTE/f+/Jz4q9Cu0YIhLcFVpVg+FsOCVehi8jmZgWOzZz33DM4CXlum3gH95GgeAzQZVeL4gTm6Cbp4vqFkD8HwBazPY8wWbMq9utu3mNZ5fotVezbzOE3kBEFbaZuc8kb00NTMUbWJp678Xf2GV7RRtx1TDQQ6XBNvsmL2+2vHq1TftmMPIyAWujtN2cl274ua2jpVpZneXEjjo7XW1q53V9ds4ODO5xIuhvGHvfLI3aixauig415uuO2+vl9+cncfsFw25zL650fXn687jqnXuP68/X3+eV3zE7y6u9eB73MlfAcfbTf3yR8CfAX+if8S/H5/EAbAxj5LN48tULvEBOh8V1AageMTXe2YHAOwHbZxrzPkSR3+ffr8TR2JDzE/4Fj8CDgEwDsW+q+9GsR07hhg2CsALBgMo2v5wNxXnQXMeGQVW7gUAyKI2m6KDsJ8Au3++F5RZO+kKNQjQcLLWgjwUjBXLltFgWWMUUlviocBgNoxNGgMjSxiYAA7zgLFo2hgIENiDU8gQCzDOmViGFAsEuBcQSDCothhpJaDRA8E5fHqH2nTbYm5fHLo1V0u3B7DAuheoeScRYabjjjuzs17cHVaTrTXmK78m9swP34d9oK/dfeXSIH2PW/MXwPvxN/bJlxw8zlYAcEyeI6gNgA/O8P8neN8xe1IHP2gTzegjvhUDfuRygmwEs2GE4mkCDIAzm2R4yAuPsIdR9k8AvMc+3L9+2UEjo4WP0FpgP19O0MzCsqxIoMsdDBvYcQyGmO0ZJRoYCKjLJWY0BAhYwGUBCgkh8MRdOKt+ruqMwAB2OcEX94U1TPbYJP0PkyyAI1S6cSIAAAAASUVORK5CYII=")!
        do {
            guard let textures: Data = account.profile.property(forName: "textures") else {
                if !(account is OfflineAccount) {
                    warn("玩家档案中不存在 textures 属性")
                }
                return defaultSkin
            }
            let json: JSON = try .init(data: textures)
            guard let url: URL = json["textures"]["SKIN"]["url"].url else {
                err("解析 textures 属性失败")
                return defaultSkin
            }
            return try await Requests.get(url).data
        } catch {
            err("获取皮肤数据失败：\(error.localizedDescription)")
            return defaultSkin
        }
    }
    
    private func requestAddMicrosoftAccount() async {
        let service: MicrosoftAuthService = .init()
        let code: MicrosoftAuthService.AuthorizationCode
        log("开始进行微软登录")
        do {
            code = try await service.start()
            log("获取设备码成功")
        } catch {
            err("添加正版账号失败：获取设备码失败：\(error.localizedDescription)")
            hint("添加正版账号失败：获取设备码失败：\(error.localizedDescription)", type: .critical)
            return
        }
        
        let authTask = Task {
            do {
                guard let pollCount = service.pollCount,
                      let pollInterval = service.pollInterval else {
                    err("pollCount 或 pollInterval 未被设置")
                    throw MicrosoftAuthService.Error.internalError
                }
                for i in 0..<pollCount {
                    try Task.checkCancellation()
                    log("第 \(i + 1)/\(pollCount) 次轮询")
                    try await Task.sleep(seconds: Double(pollInterval))
                    if try await service.poll() {
                        log("用户完成了授权")
                        break
                    }
                    if i == pollCount - 1 {
                        throw SimpleError("授权超时。")
                    }
                }
                hint("授权成功！正在完成后续登录步骤……")
                let response = try await service.authenticate()
                let account: MicrosoftAccount = .init(profile: response.profile, accessToken: response.accessToken, refreshToken: response.refreshToken)
                log("添加正版账号成功")
                hint("账号添加成功！", type: .finish)
                await MainActor.run {
                    LauncherConfig.shared.hasMicrosoftAccount = true
                    addAccount(account)
                }
            } catch {
                err("添加正版账号失败：\(error.localizedDescription)")
                hint("登录失败：\(error.localizedDescription)", type: .critical)
            }
            await MainActor.run {
                MessageBoxManager.shared.complete(with: .button(id: 0))
            }
        }
        
        if await MessageBoxManager.shared.showText(
            title: "添加正版账号",
            content: "请打开 \(code.verificationURL)，然后输入 \(code.code)，随后根据提示完成后续授权步骤。\n点击下方按钮可以一键复制并跳转！",
            .init(id: 0, label: "复制并跳转", type: .highlight) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(code.code, forType: .string)
                NSWorkspace.shared.open(code.verificationURL)
            },
            .init(id: 1, label: "取消", type: .red)
        ) == 1 {
            log("用户取消了授权")
            authTask.cancel()
        }
    }
    
    private func requestAddOfflineAccount() async {
        guard let playerName: String = await MessageBoxManager.shared.showInput(title: "玩家名") else {
            log("用户取消了添加")
            return
        }
        await MainActor.run {
            addAccount(OfflineAccount(name: playerName, uuid: UUIDUtils.uuid(ofOfflinePlayer: playerName)))
        }
    }
    
    private func addAccount(_ account: Account) {
        accounts.append(account)
        switchAccount(to: account)
    }
}
