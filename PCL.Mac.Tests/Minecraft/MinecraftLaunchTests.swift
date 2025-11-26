//
//  MinecraftLaunchTests.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/26.
//

import Testing
import Foundation
import Core

struct MinecraftLaunchTests {
    @Test func testLaunch() throws {
        let runningDirectory: URL = URL(filePath: "/Users/yizhimcqiu/minecraft/versions/1.21.10")
        if !FileManager.default.fileExists(atPath: runningDirectory.path) { return }
        let instance: MinecraftInstance = try .load(runningDirectory: runningDirectory)
        let options: LaunchOptions = .init()
        options.javaURL = URL(filePath: "/usr/bin/java")
        _ = try MinecraftLauncher(instance: instance, options: options).launch()
    }
}
