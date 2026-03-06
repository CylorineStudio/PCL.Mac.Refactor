//
//  JavaManager.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/2/2.
//

import Foundation

public final class JavaManager: ObservableObject {
    public static let shared: JavaManager = .init()
    
    @Published public private(set) var javaRuntimes: [JavaRuntime]
    
    @MainActor
    public func research() throws {
        self.javaRuntimes = try JavaSearcher.search()
    }
    
    private init() {
        do {
            self.javaRuntimes = try JavaSearcher.search()
            log("Java 搜索完成，共 \(javaRuntimes.count) 个：")
            for javaRuntime in javaRuntimes {
                let type: String = .init(describing: javaRuntime.type).padding(toLength: 4, withPad: " ", startingAt: 0)
                let version: String = .init(describing: javaRuntime.version).padding(toLength: 10, withPad: " ", startingAt: 0)
                let arch: String = .init(describing: javaRuntime.architecture).padding(toLength: 8, withPad: " ", startingAt: 0)
                let impl: String = javaRuntime.implementor.padding(toLength: 24, withPad: " ", startingAt: 0)
                log("\(type) \(version)\t\(arch)\t\(impl)\t\(javaRuntime.executableURL.path)")
            }
        } catch {
            err("搜索 Java 失败：\(error.localizedDescription)")
            self.javaRuntimes = []
        }
    }
}
