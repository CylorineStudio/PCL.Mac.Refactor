//
//  MinecraftInstance.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/4/15.
//

import Foundation

public struct MinecraftInstance_: Hashable, Identifiable, Equatable {
    public let id: UUID
    public let url: URL
    public let version: MinecraftVersion
    public let manifest: ClientManifest
    
    public var config: Config
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    public struct Config: Codable {
        public var jvmHeapSize: UInt64
        public var javaURL: URL?
    }
}
