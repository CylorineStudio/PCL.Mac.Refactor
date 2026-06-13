//
//  String+Template.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/8.
//

public extension String {
    func replacingPlaceholders(with values: [String: String], dollarPrefix: Bool = true) -> String {
        var s: String = self
        for key in values.keys {
            s = s.replacingOccurrences(of: (dollarPrefix ? "$" : "") + "{\(key)}", with: values[key]!)
        }
        return s
    }
}
