//
//  DownloadSource.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/7/5.
//

import Foundation

public protocol DownloadSource {
    func versionManifestURL() -> URL
    
    func fabricVersionListURL(for minecraftVersion: String) -> URL
    
    func replacing(_ url: URL) -> URL
}

public struct OfficialDownloadSource: DownloadSource {
    public static let shared: OfficialDownloadSource = .init()
    
    public func versionManifestURL() -> URL {
        .init(string: "https://piston-meta.mojang.com/mc/game/version_manifest.json")!
    }
    
    public func fabricVersionListURL(for minecraftVersion: String) -> URL {
        .init(string: "https://meta.fabricmc.net/v2/versions/loader/\(minecraftVersion)")!
    }
    
    public func replacing(_ url: URL) -> URL {
        url
    }
}

public struct MirrorDownloadSource: DownloadSource {
    public static let shared: MirrorDownloadSource = .init()
    
    private let bmclapiBaseURL = URL(string: "https://bmclapi2.bangbang93.com")!
    private let mcimBaseURL = URL(string: "https://mod.mcimirror.top")!
    
    public func versionManifestURL() -> URL {
        bmclapiBaseURL.appending(path: "mc/game/version_manifest.json")
    }
    
    public func fabricVersionListURL(for minecraftVersion: String) -> URL {
        bmclapiBaseURL.appending(path: "fabric-meta/v2/versions/loader/\(minecraftVersion)")
    }
    
    public func replacing(_ url: URL) -> URL {
        if url.matches(hosts: "piston-meta.mojang.com", "piston-data.mojang.com", "launchermeta.mojang.com") {
            return bmclapiBaseURL.appending(path: url.path)
        } else if url.matches(hosts: "resources.download.minecraft.net") {
            return bmclapiBaseURL.appending(path: "assets").appending(path: url.path)
        } else if url.matches(
            prefixes: "files.minecraftforge.net/maven", "maven.neoforged.net/releases",
            hosts: "libraries.minecraft.net", "maven.fabricmc.net"
        ) {
            return bmclapiBaseURL.appending(path: "maven").appending(path: resolvingMaven(url.path))
        } else if url.matches(hosts: "meta.fabricmc.net") {
            return bmclapiBaseURL.appending(path: "fabric-meta").appending(path: url.path)
        } else if url.matches(hosts: "api.modrinth.com") {
            return mcimBaseURL.appending(path: "modrinth").appending(path: url.path)
        } else if url.matches(hosts: "api.curseforge.com") {
            return mcimBaseURL.appending(path: "curseforge").appending(path: url.path)
        } else if url.matches(hosts: "cdn.modrinth.com", "edge.forgecdn.net") {
            return mcimBaseURL.appending(path: url.path)
        }
        
        return url
    }
    
    private func resolvingMaven(_ path: String) -> String {
        if path.starts(with: "maven") {
            return String(path.dropFirst("maven".count))
        } else if path.starts(with: "releases") {
            return String(path.dropFirst("releases".count))
        }
        return path
    }
}

private extension URL {
    func matches(prefixes: String..., hosts: String...) -> Bool {
        guard let scheme, let host else { return false }
        let urlStringWithoutScheme = self.absoluteString.dropFirst(scheme.count + "://".count)
        return hosts.contains(host) || prefixes.contains { urlStringWithoutScheme.hasPrefix($0) }
    }
}
