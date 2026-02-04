//
//  LaunchPrecheck.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/2/2.
//

import Foundation

public enum LaunchPrecheck {
    
    public static func check(
        for instance: MinecraftInstance,
        with options: LaunchOptions,
        hasMicrosoftAccount: Bool
    ) -> [Entry] {
        var entries: [Entry] = []
        entries += checkJava(instance: instance, currentJava: options.javaRuntime)
        entries += checkAccount(options.profile, hasMicrosoftAccount: hasMicrosoftAccount)
        return entries
    }
    
    private static func checkJava(instance: MinecraftInstance, currentJava: JavaRuntime) -> [Entry] {
        var entries: [Entry] = []
        let minVersion: Int = instance.manifest.javaVersion.majorVersion
        let actualVersion: Int = currentJava.versionNumber
        if actualVersion < minVersion {
            log("当前 Java 版本（\(actualVersion)）低于最低 Java 版本（\(minVersion)）")
            entries.append(.javaVersionTooLow(min: minVersion))
        }
        return entries
    }
    
    private static func checkAccount(_ profile: PlayerProfile, hasMicrosoftAccount: Bool) -> [Entry] {
        var entries: [Entry] = []
        if !hasMicrosoftAccount {
            entries.append(.noMicrosoftAccount)
        }
        return entries
    }
    
    public enum Entry {
        case javaVersionTooLow(min: Int)
        case noMicrosoftAccount
    }
}
