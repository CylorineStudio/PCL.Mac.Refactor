//
//  UpdateModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/26.
//

import Foundation

struct UpdateModel: Codable {
    public struct Link: Codable {
        public let name: String
        public let url: URL
    }
    
    public struct Version: Codable {
        public struct Downloads: Codable {
            public let github: URL
            public let mirror: URL
            public let size: Int
            public let sha1: String
        }
        
        public let name: String
        public let bundleVersion: Int
        public let summary: String
        public let updateLogLinks: [Link]
        public let downloads: Downloads
    }
    
    public let latestVersion: Version
}
