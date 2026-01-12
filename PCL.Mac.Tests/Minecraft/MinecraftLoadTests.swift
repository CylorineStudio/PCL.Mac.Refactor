//
//  MinecraftLoadTests.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/12.
//

import Foundation
import Core
import Testing

struct MinecraftLoadTests {
    @Test private func testLoad() throws {
        let directory: URL = FileManager.default.temporaryDirectory.appending(path: "testLoad")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        
        #expect(throws: MinecraftError.missingManifest) {
            try MinecraftInstance.load(from: directory)
        }
        FileManager.default.createFile(atPath: directory.appending(path: "testLoad.json").path, contents: "{}".data(using: .utf8)!)
        #expect(throws: MinecraftError.unknownManifestFormat) {
            try MinecraftInstance.load(from: directory)
        }
    }
}
