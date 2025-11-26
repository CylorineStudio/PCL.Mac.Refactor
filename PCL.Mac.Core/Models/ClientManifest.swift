//
//  ClientManifest.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/21.
//

import Foundation
import SwiftyJSON

public class ClientManifest {
    public let gameArguments: [Argument]
    public let jvmArguments: [Argument]
    public let assetIndex: AssetIndex
    public let downloads: Downloads
    public let id: String
    public let libraries: [Library]
    public let logging: Logging
    public let mainClass: String
    public let type: String
    
    public init(json: JSON) {
        self.gameArguments = json["arguments"]["game"].arrayValue.map(Argument.init(json:))
        self.jvmArguments = json["arguments"]["jvm"].arrayValue.map(Argument.init(json:))
        self.assetIndex = AssetIndex(json: json["assetIndex"])
        self.downloads = Downloads(json: json["downloads"])
        self.id = json["id"].stringValue
        self.libraries = json["libraries"].arrayValue.map(Library.init(json:))
        self.logging = Logging(json: json["logging"])
        self.mainClass = json["mainClass"].stringValue
        self.type = json["type"].stringValue
    }
    
    public class Argument {
        public let value: [String]
        public let rules: [Rule]
        
        public init(json: JSON) {
            if json.type == .string {
                self.value = [json.stringValue]
                self.rules = []
            } else {
                self.value = json["value"].type == .string ? [json["value"].stringValue] : json["value"].arrayValue.map(\.stringValue)
                self.rules = json["rules"].arrayValue.map(Rule.init(json:))
            }
        }
    }
    
    public class Artifact {
        public let path: String
        public let sha1: String?
        public let size: Int?
        public let url: URL?
        
        public init(path: String, sha1: String?, size: Int?, url: URL?) {
            self.path = path
            self.sha1 = sha1
            self.size = size
            self.url = url
        }
        
        public convenience init(json: JSON) {
            self.init(
                path: json["path"].stringValue,
                sha1: json["sha1"].string,
                size: json["size"].int,
                url: URL(string: json["url"].stringValue)
            )
        }
    }
    
    public class AssetIndex {
        public let id: String
        public let sha1: String
        public let size: Int
        public let totalSize: Int
        public let url: URL!
        
        public init(json: JSON) {
            self.id = json["id"].stringValue
            self.sha1 = json["sha1"].stringValue
            self.size = json["size"].intValue
            self.totalSize = json["totalSize"].intValue
            self.url = URL(string: json["url"].stringValue)
        }
    }
    
    public class Downloads {
        public let client: Artifact
        public let clientMappings: Artifact
        public let server: Artifact
        public let serverMappings: Artifact
        
        public init(json: JSON) {
            self.client = Artifact(json: json["client"])
            self.clientMappings = Artifact(json: json["client_mappings"])
            self.server = Artifact(json: json["server"])
            self.serverMappings = Artifact(json: json["server_mappings"])
        }
    }
    
    public class Library {
        public let name: String
        public let artifact: Artifact?
        public let rules: [Rule]
        public let isNativesLibrary: Bool
        
        public lazy var groupId: String = { String(name.split(separator: ":")[0]) }()
        public lazy var artifactId: String = { String(name.split(separator: ":")[1]) }()
        public lazy var version: String = { String(name.split(separator: ":")[2]) }()
        public lazy var classifier: String? = {
            let parts: [Substring] = name.split(separator: ":")
            return parts.count == 4 ? String(parts[3]) : nil
        }()
        public lazy var isRulesSatisfied: Bool = { rules.allSatisfy { $0.test() } }()
        
        public init(json: JSON) {
            self.name = json["name"].stringValue
            self.isNativesLibrary = json["natives"].exists()
            if !isNativesLibrary {
                self.artifact = .init(json: json["downloads"]["artifact"])
            } else {
                if let key = json["natives"]["osx"].string {
                    self.artifact = .init(json: json["downloads"]["classifiers"][key])
                } else {
                    self.artifact = nil
                }
            }
            self.rules = json["rules"].arrayValue.map(Rule.init(json:))
        }
    }
    
    public class Logging {
        public let argument: String
        public let file: Artifact
        
        public init(json: JSON) {
            self.argument = json["client"]["argument"].stringValue
            self.file = Artifact(json: json["client"]["file"])
        }
    }
    
    public class Rule {
        public let allow: Bool
        public let osName: String?
        public let osArch: Architecture?
        public let hasFeaturesLimit: Bool
        
        public init(json: JSON) {
            self.allow = json["action"].stringValue == "allow"
            self.osName = json["os"]["name"].string
            self.osArch = json["os"]["arch"].string.flatMap(Architecture.init(rawValue:))
            self.hasFeaturesLimit = json["features"].exists()
        }
        
        public func test() -> Bool {
            if let osName, osName != "osx" { return !allow }
            if let osArch, osArch != .arm64 { return !allow } // TODO
            if hasFeaturesLimit { return !allow } // TODO
            return allow
        }
    }
    
    /// 获取所有可用的普通依赖库。
    /// - Returns: 所有可用的普通依赖库。
    public func getLibraries() -> [Library] {
        return libraries.filter { !$0.isNativesLibrary && $0.isRulesSatisfied }
    }
    
    /// 获取所有可用的本地库。
    /// - Returns: 所有可用的本地库。
    public func getNatives() -> [Library] {
        return libraries.filter { $0.isNativesLibrary && $0.isRulesSatisfied }
    }
}
