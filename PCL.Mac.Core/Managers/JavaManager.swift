//
//  JavaManager.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/2/2.
//

import Foundation

public final class JavaManager {
    public static let shared: JavaManager = .init()
    
    public private(set) var javaRuntimes: [JavaRuntime]
    
    public func research() throws {
        self.javaRuntimes = try JavaSearcher.search()
    }
    
    private init() {
        do {
            self.javaRuntimes = try JavaSearcher.search()
        } catch {
            err("搜索 Java 失败：\(error.localizedDescription)")
            self.javaRuntimes = []
        }
    }
}
