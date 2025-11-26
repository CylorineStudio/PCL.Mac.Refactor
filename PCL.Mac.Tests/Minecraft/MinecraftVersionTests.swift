//
//  MinecraftVersionTests.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/24.
//

import Testing
import Foundation
import Core

struct MinecraftVersionTests {
    @Test func test() {
        #expect(MinecraftVersion("1.21.10") == MinecraftVersion("1.21.10"))
        #expect(MinecraftVersion("1.21.10") < MinecraftVersion("1.21.11-pre2"))
        #expect(MinecraftVersion("1.21") > MinecraftVersion("1.20.6"))
        #expect(MinecraftVersion("11.45.14").index == 0)
    }
}
