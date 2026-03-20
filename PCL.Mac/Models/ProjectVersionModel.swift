//
//  ProjectVersionModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/19.
//

import Foundation
import Core

struct ProjectVersionModel: Identifiable {
    struct Dependency: Identifiable {
        public let id: String?
        public let projectId: String
        public let project: ProjectListItemModel
    }
    
    public let id: String
    public let name: String
    public let version: String
    public let downloads: String
    public let datePublished: String
    public let requiredDependencies: [Dependency]
    public let type: ModrinthVersion.VersionType
    public let primaryFile: ModrinthVersion.File?
}
