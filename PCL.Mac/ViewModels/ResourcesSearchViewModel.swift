//
//  ResourcesSearchViewModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/16.
//

import Foundation
import Core

class ResourcesSearchViewModel: ObservableObject {
    @Published public var searchResults: [ProjectListItemModel] = []
    public let type: ModrinthProjectType
    public let loadingVM: MyLoadingViewModel = .init(text: "加载中")
    
    public init(type: ModrinthProjectType) {
        self.type = type
    }
    
    public func search(_ query: String) async throws {
        await MainActor.run {
            searchResults.removeAll()
        }
        let response: ModrinthAPIClient.SearchResponse = try await ModrinthAPIClient.shared.search(type: type, query, forVersion: nil)
        await MainActor.run {
            searchResults = response.hits.map(ProjectListItemModel.init(_:))
        }
    }
}
