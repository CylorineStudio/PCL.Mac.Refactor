//
//  AuthlibInjectorArtifacts.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/4/14.
//

import Foundation

public struct AuthlibInjectorArtifacts: Codable {
    public struct ArtifactInfo: Codable {
        public let buildNumber: Int
        public let version: String
        
        private enum CodingKeys: String, CodingKey {
            case buildNumber = "build_number", version
        }
    }
    public let latestBuildNumber: Int
    public let artifacts: [ArtifactInfo]
    
    private enum CodingKeys: String, CodingKey {
        case latestBuildNumber = "latest_build_number", artifacts
    }
}

public struct AuthlibInjectorArtifact: Codable {
    public let buildNumber: Int
    public let version: String
    public let downloadURL: URL
    public let checksums: [String: String]
    
    private enum CodingKeys: String, CodingKey {
        case buildNumber = "build_number", version, downloadURL = "download_url", checksums
    }
}
