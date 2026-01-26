//
//  PlayerProfileModel.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/14.
//

import Foundation

public struct PlayerProfileModel: Codable {
    public let name: String
    public let id: UUID
    public let properties: [Property]
    
    public init(name: String, id: UUID, properties: [Property]) {
        self.name = name
        self.id = id
        self.properties = properties
    }
    
    public func property(forName name: String) -> Data? {
        return properties.first(where: { $0.name == name })?.value
    }
    
    public enum CodingKeys: CodingKey {
        case name, id, properties
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.id = try UUIDUtils.uuidThrowing(of: container.decode(String.self, forKey: .id))
        self.properties = try container.decodeIfPresent([PlayerProfileModel.Property].self, forKey: .properties) ?? []
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(UUIDUtils.string(of: self.id), forKey: .id)
        if !self.properties.isEmpty {
            try container.encode(self.properties, forKey: .properties)
        }
    }
    
    public struct Property: Codable {
        public let name: String
        public let signature: String?
        public let value: Data
    }
}
