//
//  DownloadTests.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/24.
//

import Testing
import Foundation
import Core

struct DownloadTests {
    @Test func singleFileDownloadTest() async throws {
        let item: DownloadItem = .init(
            url: URL(string: "https://bmclapi2.bangbang93.com/version/1.21.10/json")!,
            destination: FileManager.default.temporaryDirectory.appending(path: "singleFileDownloadTest"),
            sha1: "d501809714c64141c1bf1e42f978d0b9e6caa70b"
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
}
