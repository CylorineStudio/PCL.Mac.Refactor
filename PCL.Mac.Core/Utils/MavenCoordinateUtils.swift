//
//  MavenCoordinateUtils.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/2/10.
//

import Foundation

public enum MavenCoordinateUtils {
    public struct MavenCoordinate {
        public var groupId: String
        public var artifactId: String
        public var version: String
        public var classifier: String?
        public var name: String { "\(groupId):\(artifactId):\(version)" + (classifier != nil ? ":\(classifier!)" : "") }
        
        public init(groupId: String, artifactId: String, version: String, classifier: String?) {
            self.groupId = groupId
            self.artifactId = artifactId
            self.version = version
            self.classifier = classifier
        }
        
        public static func parse(coord: String) -> MavenCoordinate {
            let parts: [String] = coord.split(separator: ":").map(String.init)
            let groupId: String = parts.count >= 1 ? parts[0] : ""
            let artifactId: String = parts.count >= 2 ? parts[1] : ""
            let version: String = parts.count >= 3 ? parts[2] : ""
            let classifier: String? = parts.count >= 4 ? parts[3] : nil
            return .init(groupId: groupId, artifactId: artifactId, version: version, classifier: classifier)
        }
    }
    
    public static func path(of coord: String) -> String {
        let parsed: MavenCoordinate = .parse(coord: coord)
        let path: String = "\(parsed.groupId.replacingOccurrences(of: ".", with: "/"))/\(parsed.artifactId)/\(parsed.version)/"
        if let classifier = parsed.classifier {
            return path + "\(parsed.artifactId)-\(parsed.version)-\(classifier).jar"
        }
        return path + "\(parsed.artifactId)-\(parsed.version).jar"
    }
}
