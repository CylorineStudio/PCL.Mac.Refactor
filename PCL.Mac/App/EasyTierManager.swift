//
//  EasyTierManager.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/15.
//

import Foundation
import SwiftScaffolding
import Core
import SwiftyJSON

enum EasyTierManager {
    public static let easyTier: EasyTier = .init(
        coreURL: URLConstants.easyTierURL.appending(path: "easytier-core"),
        cliURL: URLConstants.easyTierURL.appending(path: "easytier-cli"),
        logURL: URLConstants.logsDirectoryURL.appending(path: "easytier.log")
    )
    
    public static func checkEasyTier() -> Bool {
        return FileUtils.isExecutable(at: easyTier.coreURL)
            && FileUtils.isExecutable(at: easyTier.cliURL)
    }
    
    public static func createEasyTierDownloadTask() async throws -> MyTask<EmptyModel> {
        let json: JSON = try await Requests.get("https://api.ceciliastudio.top/easytier/download_url?arch=arm64").json()
        if let error = json["error"].string {
            throw SimpleError("API 调用失败：\(error)")
        }
        guard let coreURL: URL = json["data"]["easytier-core"]["url"].url,
              let cliURL: URL = json["data"]["easytier-cli"]["url"].url else {
            err("/easytier/download_url 返回了未知的响应格式：\(json.rawString([:]) ?? "")")
            throw SimpleError("API 返回了未知的响应格式。")
        }
        let coreDownloadItem: DownloadItem = .init(
            url: coreURL,
            destination: easyTier.coreURL,
            sha1: json["data"]["easytier-core"]["sha1"].string
        )
        let cliDownloadItem: DownloadItem = .init(
            url: cliURL,
            destination: easyTier.cliURL,
            sha1: json["data"]["easytier-cli"]["sha1"].string
        )
        
        return .init(
            name: "下载 EasyTier",
            model: .init(),
            .init(0, "下载 easytier-core") { task, _ in
                try await SingleFileDownloader.download(coreDownloadItem, replaceMethod: .skip, progressHandler: task.setProgress(_:))
            },
            .init(0, "下载 easytier-cli") { task, _ in
                try await SingleFileDownloader.download(cliDownloadItem, replaceMethod: .skip, progressHandler: task.setProgress(_:))
            }
        )
    }
}
