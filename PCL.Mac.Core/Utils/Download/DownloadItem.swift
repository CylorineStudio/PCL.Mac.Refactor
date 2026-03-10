//
//  DownloadItem.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2025/11/22.
//

import Foundation

public struct DownloadItem: Hashable {
    public let url: URL
    public let destination: URL
    public let sha1: String?
    public let executable: Bool
    
    public init(url: URL, destination: URL, sha1: String?, executable: Bool = false) {
        self.url = url
        self.destination = destination
        self.sha1 = sha1
        self.executable = executable
    }
}

public enum ReplaceMethod {
    case replace, skip, `throw`
}
