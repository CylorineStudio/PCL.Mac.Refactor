//
//  Utils.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/2/17.
//

import Foundation

public enum Utils {
    public static func replace(_ string: String, withValues values: [String: String], withDollarPrefix: Bool = true) -> String {
        var s: String = string
        for key in values.keys {
            s = s.replacingOccurrences(of: (withDollarPrefix ? "$" : "") + "{\(key)}", with: values[key]!)
        }
        return s
    }
}
