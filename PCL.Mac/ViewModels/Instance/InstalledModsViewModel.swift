//
//  InstalledModsViewModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/7.
//

import Foundation
import Core
import Combine

@MainActor
class InstalledModsViewModel: ObservableObject {
    @Published public var mods: [ModDisplayModel]?
    @Published public var supportMods: Bool = true
    @Published public var currentRepositoryId: UUID
    private var cancellables: Set<AnyCancellable> = []
    private let instanceManager: InstanceManager
    private let id: String
    private let service: ModLoadService
    
    init(instanceManager: InstanceManager, id: String) {
        self.instanceManager = instanceManager
        self.id = id
        self.currentRepositoryId = instanceManager.currentRepositoryId
        self.service = .init(remoteLookupService: .init(curseforgeClient: .init(apiKey: "")), cache: .shared)
        
        instanceManager.$currentRepositoryId
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentRepositoryId, on: self)
            .store(in: &cancellables)
    }
    
    func load() async throws {
        guard let instance = instanceManager.currentRepository.instance(named: id) else {
            throw SimpleError("实例不存在。")
        }
        if instance.modLoader == nil {
            await MainActor.run {
                supportMods = false
            }
            return
        }
        let modsDirectory = instance.url.appending(path: "mods")
        let result: [ModDisplayModel] = try await service.loadMods(in: modsDirectory).values.lazy
            .map(ModDisplayModel.init)
            .sorted { $0.name.compare($1.name, options: .literal) == .orderedAscending }
        await MainActor.run {
            mods = result
        }
    }
}
