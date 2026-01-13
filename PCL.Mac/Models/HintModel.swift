//
//  HintModel.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/13.
//

import Foundation

struct HintModel: Identifiable, Equatable {
    public let text: String
    public let type: `Type`
    public let id: UUID = .init()
    
    public enum `Type` {
        case info, finish, critical
    }
}
