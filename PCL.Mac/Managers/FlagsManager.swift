//
//  FlagsManager.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/7/14.
//

import Foundation
import Core

class FlagsManager: ObservableObject {
    public static var shared: FlagsManager!
    @Published private(set) var enabledFlags: Set<FeatureFlag>
    private let defaultFlags = Set<FeatureFlag>(arrayLiteral: .deduplicateLibraries)
    
    init(enabledFlags: Set<FeatureFlag>?) {
        if let enabledFlags {
            self.enabledFlags = enabledFlags
        } else {
            self.enabledFlags = defaultFlags
        }
        for flag in FeatureFlag.allCases {
            applyChange(flag, enabled: isEnabled(flag))
        }
        debug("已开启的功能：\(self.enabledFlags)")
    }
    
    func isEnabled(_ flag: FeatureFlag) -> Bool {
        return enabledFlags.contains(flag)
    }
    
    func enable(_ flag: FeatureFlag) {
        setEnabled(flag, enabled: true)
    }
    
    func disable(_ flag: FeatureFlag) {
        setEnabled(flag, enabled: false)
    }
    
    func setEnabled(_ flag: FeatureFlag, enabled: Bool) {
        if enabled {
            enabledFlags.insert(flag)
        } else {
            enabledFlags.remove(flag)
        }
        log("\(flag) 已被\(enabled ? "开启" : "关闭")")
        applyChange(flag, enabled: enabled)
    }
    
    private func applyChange(_ flag: FeatureFlag, enabled: Bool) {
        switch flag {
        case .deduplicateLibraries:
            ClientManifest.deduplicateLibraries = enabled
        default:
            break
        }
    }
}

enum FeatureFlag: String, Codable, CaseIterable {
    case deduplicateLibraries
    case multiplayer
}
