//
//  MessageBoxModel.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/20.
//

import Foundation

struct MessageBoxModel {
    public let title: String
    public let body: Body
    public let level: Level
    
    public enum Body {
        case text(text: String)
    }
    
    public enum Level {
        case info, error
    }
}
