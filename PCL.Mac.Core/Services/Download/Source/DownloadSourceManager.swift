//
//  DownloadSourceManager.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/24.
//

import Foundation

public class DownloadSourceManager {
    public static var shared: DownloadSourceManager! = .init(option: .auto)
    
    private static let officialSource: OfficialDownloadSource = .shared
    private static let mirrorSource: MirrorDownloadSource = .shared
    
    public private(set) var currentSource: DownloadSource
    public private(set) var option: DownloadSourceOption
    
    public init(option: DownloadSourceOption) {
        self.currentSource = option == .preferredMirror ? Self.mirrorSource : Self.officialSource
        self.option = option
    }
    
    public func setOption(_ option: DownloadSourceOption) {
        if self.option == option { return }
        log("下载源设置切换：\(self.option) → \(option)，当前下载源：\(type(of: currentSource))")
        self.option = option
        switch option {
        case .preferredOfficial, .auto:
            currentSource = Self.officialSource
        case .preferredMirror:
            currentSource = Self.mirrorSource
        }
    }
    
    public func switchToMirror() {
        guard option == .auto else {
            warn("试图切换至镜像源，但被下载源选项阻止")
            return
        }
        currentSource = Self.mirrorSource
    }
    
    public var concurrentLimit: Int { currentSource is OfficialDownloadSource ? 12 : 8 }
}

public enum DownloadSourceOption: Codable {
    case preferredOfficial
    case auto
    case preferredMirror
}
