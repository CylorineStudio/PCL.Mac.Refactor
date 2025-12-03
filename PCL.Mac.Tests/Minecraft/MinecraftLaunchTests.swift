//
//  MinecraftLaunchTests.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/26.
//

import Testing
import Foundation
import Core
import SwiftyJSON

struct MinecraftLaunchTests {
    @Test func testLaunch() throws {
        let runningDirectory: URL = FileManager.default.homeDirectoryForCurrentUser.appending(path: "minecraft")
        if !FileManager.default.fileExists(atPath: runningDirectory.path) { return }
        var options: LaunchOptions = .init()
        options.javaURL = URL(fileURLWithPath: "/usr/bin/java")
        options.runningDirectory = runningDirectory
        options.manifest = .init(json: try JSON(data: Data(contentsOf: runningDirectory.appending(path: "1.21.10.json"))))
        _ = try MinecraftLauncher(options: options).launch()
    }
}
