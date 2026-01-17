//
//  Metadata.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/1/17.
//

import Foundation

public enum Metadata {
    public static let appVersion: String = { value(forKey: "CFBundleShortVersionString") }()
    
    public static let debugMode: Bool = { boolValue(forKey: "DebugMode") }()
    
    private static func value(forKey key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            err("加载 \(key) 失败：该键不存在或值类型错误")
            return ""
        }
        return value
    }
    
    private static func boolValue(forKey key: String) -> Bool {
        return (value(forKey: key) as NSString).boolValue
    }
}
