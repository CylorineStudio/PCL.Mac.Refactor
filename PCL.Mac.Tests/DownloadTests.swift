//
//  DownloadTests.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/24.
//

import Testing
import Foundation
import Core
import SwiftyJSON

struct DownloadTests {
    @Test func singleFileDownloadTest() async throws {
        let item: DownloadItem = .init(
            url: URL(string: "https://bmclapi2.bangbang93.com/version/1.21.10/json")!,
            destination: FileManager.default.temporaryDirectory.appending(path: "singleFileDownloadTest"),
            sha1: "b8ac7ed26100bd79830df1de207fbeefe7fab62f"
        )
        
        try await SingleFileDownloader.download(item, replaceMethod: .replace)
        
        try await SingleFileDownloader.download(
            url: item.url,
            destination: item.destination,
            sha1: item.sha1,
            replaceMethod: .replace
        )
        
        await #expect(throws: DownloadError.fileExists) {
            try await SingleFileDownloader.download(
                url: item.url,
                destination: item.destination,
                sha1: item.sha1,
                replaceMethod: .throw
            )
        }
        
        await #expect(throws: DownloadError.checksumMismatch) {
            try await SingleFileDownloader.download(
                url: item.url,
                destination: item.destination,
                sha1: "da39a3ee5e6b4b0d3255bfef95601890afd80709",
                replaceMethod: .throw
            )
        }
        
        await #expect(throws: DownloadError.badStatusCode(code: 404)) {
            try await SingleFileDownloader.download(
                url: URL(string: "https://bmclapi2.bangbang93.com/version/11.45.14/json")!,
                destination: item.destination,
                sha1: nil,
                replaceMethod: .throw
            )
        }
    }
    
    @Test func multiFileDownloadTest() async throws {
        let data: Data = try await URLSession.shared.data(from: URL(string: "https://piston-meta.mojang.com/v1/packages/48fc0ab195b88bc562d672cdcf7997de42fe9d51/27.json").unwrap()).0
        let assetIndex: AssetIndex = try .init(json: .init(data: data))
        let tempDirectory: URL = FileManager.default.temporaryDirectory.appending(path: "multiFileDownloadTest")
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: false)
        let root: URL = try URL(string: "https://resources.download.minecraft.net").unwrap()
        let items: [DownloadItem] = assetIndex.objects.map { .init(
            url: root.appending(path: "\($0.hash.prefix(2))/\($0.hash)"), destination: tempDirectory.appending(path: $0.hash), sha1: $0.hash)
        }
        try await MultiFileDownloader(items: items, concurrentLimit: 64, replaceMethod: .skip, progressHandler: { print($0 * 100) }).start()
        try FileManager.default.removeItem(at: tempDirectory)
    }
}
