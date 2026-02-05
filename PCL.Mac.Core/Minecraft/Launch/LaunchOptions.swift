//
//  LaunchOptions.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/21.
//

import Foundation

public struct LaunchOptions {
    public var profile: PlayerProfile!
    public var accessToken: String!
    public var javaRuntime: JavaRuntime!
    public var runningDirectory: URL!
    public var manifest: ClientManifest!
    public var repository: MinecraftRepository!
    public var memory: UInt64 = 4096
    public var demo: Bool = false
    
    public func validate() throws {
        if profile == nil || accessToken == nil { throw LaunchError.missingAccount }
        if javaRuntime == nil { throw LaunchError.missingJava }
        if runningDirectory == nil { throw LaunchError.missingRunningDirectory }
        if manifest == nil { throw LaunchError.missingManifest }
        if repository == nil { throw LaunchError.missingRepository }
    }
    
    public init() {}
}
