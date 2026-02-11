//
//  NativesMapper.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/2/10.
//

// 直接从老项目里抄的
// 这段代码现在只有上帝能看懂了.jpg

import Foundation

public enum NativesMapper {
    /// 将清单中的 natives 转换为指定架构可用的版本。
    public static func map(_ manifest: ClientManifest, to architecture: Architecture = .systemArchitecture()) -> ClientManifest {
        let natives: [ClientManifest.Library] = manifest.getNatives()
        var newLibraries: [ClientManifest.Library] = []
        
        if natives.isEmpty {
            return manifest
        }
        
        if architecture != .arm64 {
            newLibraries += manifest.libraries
            for library in natives {
                if library.groupId.starts(with: "org.lwjgl") && library.artifactId != "lwjgl-platform" {
                    newLibraries.append(setArtifact(for: library, to: "org.lwjgl:\(library.artifactId):3.3.2:natives-macos"))
                    continue
                }
                newLibraries.append(library)
            }
            return manifest.setLibraries(to: newLibraries)
        }
        
        for library in manifest.getLibraries() {
            if library.groupId == "org.lwjgl" && library.version.starts(with: "3.") && library.version != "3.3.3" {
                if library.artifactId == "lwjgl-glfw" {
                    newLibraries.append(setArtifact(for: library, to: "org.glavo.hmcl.mmachina:lwjgl-glfw:3.3.1-mmachina.1", in: URL(string: "https://repo1.maven.org/maven2/")!))
                    continue
                } else {
                    newLibraries.append(setVersion(for: library, to: "3.3.1"))
                    continue
                }
            } else if library.groupId == "net.java.dev.jna" && library.version == "4.4.0" {
                newLibraries.append(setVersion(for: library, to: "5.14.0"))
                continue
            } else if library.groupId == "ca.weblite" && library.artifactId == "java-objc-bridge" {
                newLibraries.append(setArtifact(for: library, to: "org.glavo.hmcl.mmachina:java-objc-bridge:1.1.0-mmachina.1", in: URL(string: "https://repo1.maven.org/maven2/")!))
                continue
            }
            newLibraries.append(library)
        }
        
        for library in natives {
            if library.groupId == "org.lwjgl" {
                if library.version.starts(with: "3.") && library.version != "3.3.3" {
                    newLibraries.append(setArtifact(for: library, to: "org.lwjgl:\(library.artifactId):3.3.1:natives-macos-arm64"))
                    continue
                }
            } else if library.groupId == "org.lwjgl.lwjgl" && library.artifactId == "lwjgl-platform" {
                newLibraries.append(setArtifact(for: library, to: "org.glavo.hmcl:lwjgl2-natives:2.9.3-rc1-osx-arm64", in: URL(string: "https://repo1.maven.org/maven2/")!))
                continue
            } else if library.groupId == "ca.weblite" && library.artifactId == "java-objc-bridge" {
                newLibraries.append(setArtifact(for: library, to: "org.glavo.hmcl.mmachina:java-objc-bridge:1.1.0-mmachina.1", in: URL(string: "https://repo1.maven.org/maven2/")!))
                continue
            }
            newLibraries.append(library)
        }
        return manifest.setLibraries(to: newLibraries)
    }
    
    private static func setArtifact(for library: ClientManifest.Library, to name: String, in urlRoot: URL = .init(string: "https://libraries.minecraft.net/")!) -> ClientManifest.Library {
        log("已将 \(library.name) 转换为 \(name)")
        let path: String = MavenCoordinateUtils.path(of: name)
        return .init(
            name: name,
            artifact: .init(path: path, sha1: nil, size: nil, url: urlRoot.appending(path: path)),
            rules: library.rules,
            isNativeLibrary: library.isNativesLibrary
        )
    }
    
    private static func setVersion(for library: ClientManifest.Library, to version: String) -> ClientManifest.Library {
        var coord: MavenCoordinateUtils.MavenCoordinate = .parse(coord: library.name)
        coord.version = version
        return setArtifact(for: library, to: coord.name)
    }
}
