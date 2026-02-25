//
//  ModLoader.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/2/11.
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
