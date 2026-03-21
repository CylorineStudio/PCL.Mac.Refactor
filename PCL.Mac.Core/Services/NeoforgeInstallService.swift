//
//  NeoforgeInstallService.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/21.
//

import Foundation

public class NeoforgeInstallService: ForgeInstallService {
    override func installerDownloadURL() -> URL {
        if minecraftVersion.id == "1.20.1" {
            let version: String = !self.version.hasPrefix("1.20.1-") ? "1.20.1-\(self.version)" : self.version
            return .init(string: "https://maven.neoforged.net/releases/net/neoforged/forge/\(version)/forge-\(version)-installer.jar")!
        }
        return .init(string: "https://maven.neoforged.net/releases/net/neoforged/neoforge/\(version)/neoforge-\(version)-installer.jar")!
    }
}
