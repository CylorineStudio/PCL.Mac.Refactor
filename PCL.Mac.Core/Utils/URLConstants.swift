//
//  URLConstants.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/11/8.
//

import Foundation

public struct URLConstants {
    public static let contentsURL: URL = Bundle.main.bundleURL.appending(path: "Contents")
    public static let resourcesURL: URL = contentsURL.appending(path: "Resources")
    
    public static let applicationSupportURL: URL = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library/Application Support/PCL.Mac.Refactor")
    public static let logsDirectoryURL: URL = applicationSupportURL.appending(path: "Logs")
    public static let configURL: URL = applicationSupportURL.appending(path: "config.json")
    public static let cacheURL: URL = applicationSupportURL.appending(path: "Caches")
    public static let temperatureURL: URL = applicationSupportURL.appending(path: "Temp")
    public static let authlibInjectorURL: URL = applicationSupportURL.appending(path: "authlib-injector.jar")
    public static let easyTierURL: URL = applicationSupportURL.appending(path: "EasyTier")
    
    public static func createDirectories() {
        let fileManager: FileManager = .default
        try? fileManager.createDirectory(at: applicationSupportURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: logsDirectoryURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: temperatureURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: easyTierURL, withIntermediateDirectories: true)
    }
}
