//
//  ForgeInstallProfile.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/2/16.
//

import Foundation

public struct ForgeInstallProfile: Codable {
    public let data: [String: DataEntry]
    public let processors: [Processor]
    public let libraries: [Library]
    public let clientManifestPath: String
    
    private enum CodingKeys: String, CodingKey {
        case data
        case processors
        case libraries
        case clientManifestPath = "json"
    }
    
    public enum Side: String, Codable {
        case client, server
    }
    
    public struct DataEntry: Codable {
        public let client: String
        public let server: String
    }
    
    public struct Processor: Codable {
        public let sides: [Side]?
        public let jar: String
        public let classpath: [String]
        public let args: [String]
        public let outputs: [String: String]?
    }
    
    public struct Library: Codable {
        public let name: String
        public let artifact: ClientManifest.Artifact
        
        private enum CodingKeys: String, CodingKey {
            case name, downloads
        }
        
        private enum DownloadsCodingKeys: String, CodingKey {
            case artifact
        }
        
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.artifact = try container.nestedContainer(keyedBy: DownloadsCodingKeys.self, forKey: .downloads)
                .decode(ClientManifest.Artifact.self, forKey: .artifact)
        }
        
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            var downloadsContainer = container.nestedContainer(keyedBy: DownloadsCodingKeys.self, forKey: .downloads)
            try downloadsContainer.encode(artifact, forKey: .artifact)
        }
    }
}
