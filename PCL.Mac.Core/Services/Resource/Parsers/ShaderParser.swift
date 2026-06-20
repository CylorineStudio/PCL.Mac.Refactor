//
//  ShaderParser.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/16.
//

import Foundation
import ZIPFoundation

enum ShaderParser: ResourceParser {
    static let type: ResourceType = .shader
    
    static func canHandle(fileURL: URL, archive: Archive) -> Bool {
        return archive.contains { $0.path.starts(with: "shaders/") }
    }
    
    static func parse(fileURL: URL, archive: Archive, remoteInfo: ResourceRemoteLookupService.RemoteResourceInfo?) -> ResourceParseResult? {
        return .init(
            name: remoteInfo?.name ?? fileURL.deletingAllPathExtensions().lastPathComponent,
            version: remoteInfo?.version,
            description: remoteInfo?.description,
            iconPath: nil,
            loaders: []
        )
    }
}
