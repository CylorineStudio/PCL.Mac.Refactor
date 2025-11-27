//
//  LaunchOptions.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/21.
//

import Foundation

public struct LaunchOptions {
    public var javaURL: URL!
    public var runningDirectory: URL!
    public var manifest: ClientManifest!
    public var memory: Int = 4096
    
    public func validate() throws {
        if javaURL == nil { throw LaunchError.missingJava }
        if runningDirectory == nil { throw LaunchError.missingRunningDirectory }
        if manifest == nil { throw LaunchError.missingManifest }
        if memory <= 0 { throw LaunchError.invalidMemory }
    }
    
    public init() {}
}
