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
    @Published public var query: String = ""
    public let type: ModrinthProjectType
    public let loadingVM: MyLoadingViewModel = .init(text: "加载中")
    private var lastSearchResponse: ModrinthAPIClient.SearchResponse?
    
    public var totalPages: Int {
        guard let lastSearchResponse else { return 0 }
        return Int(ceil(Double(lastSearchResponse.totalHits) / Double(lastSearchResponse.limit)))
    }
    
    public init(type: ModrinthProjectType) {
        self.type = type
    }
    
    public func search(_ query: String, pageIndex: Int = 0) async throws {
        await MainActor.run {
            self.query = query
            loadingVM.reset()
            searchResults.removeAll()
        }
        let response: ModrinthAPIClient.SearchResponse = try await ModrinthAPIClient.shared.search(type: type, query, forVersion: nil, pageIndex: pageIndex)
        await MainActor.run {
            lastSearchResponse = response
            searchResults = response.hits.filter { $0.clientCompatibility != .unsupported }.map(ProjectListItemModel.init(_:))
        }
    }
    
    public func changePage(_ page: Int) async throws {
        try await search(query, pageIndex: page)
    }
}
