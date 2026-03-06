//
//  InstanceConfigViewModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/6.
//

import Foundation
import Core

@MainActor
class InstanceConfigViewModel: ObservableObject {
    @Published public var instance: MinecraftInstance?
    @Published public var jvmHeapSize: String = ""
    @Published public var javaDescription: String = "无"
    @Published public var loaded: Bool = false
    
    public var description: String {
        guard let instance else { return "" }
        if let modLoader: ModLoader = instance.modLoader {
            return "\(instance.version.description)，\(modLoader)"
        }
        return instance.version.description
    }
    
    public var iconName: String {
        if let modLoader: ModLoader = instance?.modLoader {
            return modLoader.description
        }
        return "GrassBlock"
    }
    
    public let id: String
    
    public init(id: String) {
        self.id = id
    }
    
    public func load() async throws {
        let instance: MinecraftInstance = try InstanceManager.shared.loadInstance(id)
        await MainActor.run {
            self.instance = instance
            self.jvmHeapSize = instance.config.jvmHeapSize.description
            if let runtime: JavaRuntime = instance.javaRuntime() {
                self.javaDescription = runtime.description
            }
            self.loaded = true
        }
    }
    
    public func javaList() -> [JavaRuntime] {
        return JavaManager.shared.javaRuntimes
            .filter { $0.executableURL != instance?.config.javaURL }
            .sorted { $0.version > $1.version }
    }
    
    @MainActor
    public func setHeapSize(_ heapSize: UInt64) {
        guard let instance else { return }
        instance.setJVMHeapSize(heapSize)
    }
    
    @MainActor
    public func switchJava(to runtime: JavaRuntime) throws {
        guard let instance else { return }
        if runtime.majorVersion < instance.manifest.javaVersion.majorVersion {
            throw Error.invalidJavaVersion(min: instance.manifest.javaVersion.majorVersion)
        }
        instance.setJava(url: runtime.executableURL)
        javaDescription = runtime.description
    }
    
    public enum Error: Swift.Error {
        case invalidJavaVersion(min: Int)
    }
}
