//
//  VersionManifest.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/2.
//

import Foundation
import SwiftyJSON

public struct VersionManifest {
    public let latestRelease: String
    public let latestSnapshot: String?
    public let versions: [Version]
    
    public init(json: JSON) {
        self.latestRelease = json["latest"]["release"].stringValue
        let latestSnapshot: String = json["latest"]["snapshot"].stringValue
        self.latestSnapshot = latestSnapshot == latestRelease ? nil : latestSnapshot
        self.versions = json["versions"].arrayValue.compactMap(Version.init(json:))
    }
    
    public struct Version {
        private static let dateFormatter: ISO8601DateFormatter = {
            let formatter: ISO8601DateFormatter = .init()
            formatter.timeZone = .current
            return formatter
        }()
        
        public let id: String
        public let type: MinecraftVersion.VersionType
        public let url: URL
        public let time: Date
        public let releaseTime: Date
        
        fileprivate init?(json: JSON) {
            guard let url = URL(string: json["url"].stringValue),
                  let time = Self.dateFormatter.date(from: json["time"].stringValue),
                  let releaseTime = Self.dateFormatter.date(from: json["releaseTime"].stringValue),
                  let versionType = MinecraftVersion.VersionType(stringValue: json["type"].stringValue)
            else { return nil }
            self.id = json["id"].stringValue
            self.type = versionType
            self.url = url
            self.time = time
            self.releaseTime = releaseTime
        }
    }
    
    public func getIndex(_ id: String) -> Int {
        guard let index = versions.firstIndex(where: { $0.id == id }) else { return -1 }
        return versions.count - index
    }
    
    public func getVersion(_ id: String) -> Version? {
        return versions.first(where: { $0.id == id })
    }
}
