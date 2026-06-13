//
//  HomepageViewModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/2.
//

import SwiftUI

class HomepageViewModel: ObservableObject {
    @Published public private(set) var homepage: Homepage?
    private var loadTask: Task<Homepage, Error>?
    
    public func load(from source: HomepageService.Source) async throws {
        let task: Task<Homepage, Error> = .detached {
            let service = HomepageService()
            return try await service.load(from: source)
        }
        self.loadTask = task
        
        let result: Homepage = try await task.value
        self.loadTask = nil
        await MainActor.run {
            self.homepage = result
        }
    }
}
