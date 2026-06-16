//
//  ResourceParser.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/15.
//

import Foundation
import ZIPFoundation

protocol ResourceParser {
    static var type: ResourceType { get }
    
    static func canHandle(fileURL: URL, archive: Archive) -> Bool
    
    static func parse(fileURL: URL, archive: Archive, remoteInfo: ResourceRemoteLookupService.RemoteResourceInfo?) -> ResourceParseResult?
}

struct ResourceParseResult {
    let name: String
    let version: String?
    let description: String?
    let iconPath: String?
    let loaders: [ModLoader]
}
