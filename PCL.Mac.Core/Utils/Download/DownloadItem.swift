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
    public let checksums: [String: String]?
    public let executable: Bool
    
    public init(url: URL, destination: URL, checksums: [String: String]?, executable: Bool = false) {
        self.url = url
        self.destination = destination
        self.checksums = checksums
        self.executable = executable
    }
    
    public init(url: URL, destination: URL, sha1: String?, executable: Bool = false) {
        self.init(
            url: url,
            destination: destination,
            checksums: sha1.map { ["sha1": $0] },
            executable: executable
        )
    }
}

public enum ReplaceMethod {
    case replace, skip, `throw`
}
