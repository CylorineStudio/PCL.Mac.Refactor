//
//  AccountTypeExtension.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/2/2.
//

import Foundation
import Core

extension AccountType {
    public var localized: String {
        switch self {
        case .offline: "离线账号"
        case .microsoft: "正版账号"
        }
    }
}
