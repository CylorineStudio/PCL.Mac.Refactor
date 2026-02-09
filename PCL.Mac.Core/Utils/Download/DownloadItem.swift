//
//  DownloadItem.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/22.
//

import Foundation

public struct DownloadItem: Hashable {
    public let url: URL
    public let destination: URL
    public let sha1: String?
    
    public init(url: URL, destination: URL, sha1: String?) {
        self.url = url
        self.destination = destination
        self.sha1 = sha1
    }
}

public enum ReplaceMethod {
    case replace, skip, `throw`
}
