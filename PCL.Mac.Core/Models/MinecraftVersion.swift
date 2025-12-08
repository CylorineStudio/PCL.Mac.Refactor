//
//  MinecraftVersion.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/24.
//

import Foundation

public class MinecraftVersion: Comparable, Equatable, CustomStringConvertible {
    public let id: String
    public let index: Int
    
    public init(_ id: String) {
        self.id = id
        self.index = CoreState.versionManifest?.getIndex(id) ?? .max
    }
    
    public static func == (lhs: MinecraftVersion, rhs: MinecraftVersion) -> Bool {
        return lhs.id == rhs.id
    }
    
    public static func < (lhs: MinecraftVersion, rhs: MinecraftVersion) -> Bool {
        return lhs.index > rhs.index
    }
    
    public lazy var description: String = { id }()
    
    public enum VersionType {
        case release, snapshot, old, aprilFool
        
        init?(stringValue: String) {
            switch stringValue {
            case "release": self = .release
            case "snapshot": self = .snapshot
            case "old_beta", "old_alpha": self = .old
            default: return nil
            }
        }
    }
}
