//
//  MinecraftLoadTests.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/1/12.
//

import Foundation
@testable import Core
import Testing

struct MinecraftLoadTests {
    @Test private func testLoad() throws {
        let directory: URL = FileManager.default.temporaryDirectory.appending(path: "testLoad")
        if FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.removeItem(at: directory)
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        
        #expect(throws: MinecraftError.missingManifest) {
            try MinecraftInstance.load(from: directory)
        }
        FileManager.default.createFile(atPath: directory.appending(path: "testLoad.json").path, contents: "{}".data(using: .utf8)!)
        #expect(throws: ClientManifest.LoadError.formatError) {
            try MinecraftInstance.load(from: directory)
        }
    }
}

extension ClientManifest.LoadError: @retroactive Equatable {
    public static func == (lhs: Core.ClientManifest.LoadError, rhs: Core.ClientManifest.LoadError) -> Bool {
        switch (lhs, rhs) {
        case (.fileNotFound, .fileNotFound): true
        case (.formatError, .formatError): true
        case (.missingParentManifest, .missingParentManifest): true
        case (.failedToRead(_), .failedToRead(_)): true
        default: false
        }
    }
}
