//
//  ProjectListItemModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/18.
//

import Foundation

struct ProjectListItemModel: Identifiable {
    public let id: String
    public let title: String
    public let description: String
    public let iconURL: URL?
    public let tags: [String]
    public let supportedGameVersions: String
    public let downloads: String
    public let lastUpdate: String
}
