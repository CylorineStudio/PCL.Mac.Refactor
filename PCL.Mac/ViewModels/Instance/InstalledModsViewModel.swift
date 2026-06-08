//
//  InstalledModsViewModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/7.
//

import Foundation
import Core

class InstalledModsViewModel: ObservableObject {
    @Published public var mods: [ModDisplayModel]?
    private let instanceManager: InstanceManager
    private let id: String
    private let service: ModLoadService
    
    init(instanceManager: InstanceManager, id: String) {
        self.instanceManager = instanceManager
        self.id = id
        self.service = .init(remoteLookupService: .init(curseforgeClient: .init(apiKey: "")), cache: .shared)
    }
    
    func load() async throws {
        let modsDirectory = await instanceManager.currentRepository.instance(named: id)!.url.appending(path: "mods")
        let result: [ModDisplayModel] = try await service.loadMods(in: modsDirectory).values.lazy
            .map(ModDisplayModel.init)
            .sorted { $0.name.compare($1.name, options: .literal) == .orderedAscending }
        await MainActor.run {
            mods = result
        }
    }
}
