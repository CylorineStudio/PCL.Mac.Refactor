//
//  ModLoader.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/2/11.
//

import Foundation

public enum ModLoader: Int, CustomStringConvertible {
    case fabric, forge
    
    public var description: String {
        switch self {
        case .fabric: "Fabric"
        case .forge: "Forge"
        }
    }
}
