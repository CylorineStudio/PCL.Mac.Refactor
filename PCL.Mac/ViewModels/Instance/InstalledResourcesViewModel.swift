//
//  InstalledResourcesViewModel.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/7.
//

import Foundation
import Core
import Combine

@MainActor
class InstalledResourcesViewModel: ObservableObject {
    @Published public var resources: [ResourceDisplayModel]?
    @Published public var supportMods: Bool = true
    @Published public var currentRepositoryId: UUID
    @Published public var currentPage: Int = 0
    @Published public var pageCount: Int = 0
    private var cancellables: Set<AnyCancellable> = []
    private var loadResult: [(URL, Resource)]?
    private var convertTask: Task<Void, Never>?
    private let instance: MinecraftInstance?
    private let id: String
    private let type: ResourceType
    private let entriesPerPage: Int = 20
    
    private let cache: ResourceCache = .shared
    private let remoteLookupService: ResourceRemoteLookupService
    
    init(instanceManager: InstanceManager, id: String, type: ResourceType) {
        self.instance = instanceManager.currentRepository.instance(named: id)
        self.id = id
        self.type = type
        self.currentRepositoryId = instanceManager.currentRepositoryId
        self.remoteLookupService = .init(curseforgeClient: .init(apiKey: Secrets.shared.curseforgeApiKey ?? ""))
        
        instanceManager.$currentRepositoryId
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentRepositoryId, on: self)
            .store(in: &cancellables)
    }
    
    func load(resetPage: Bool = true) async throws {
        guard let instance else { throw SimpleError("实例不存在。") }
        
        let resources: [URL: Resource] = switch type {
        case .mod: try await loadMods(of: instance)
        default: [:]
        }
        
        let result: [(URL, Resource)] = resources
            .map { ($0, $1) }
            .sorted { $0.1.name.compare($1.1.name, options: .literal) == .orderedAscending }
        
        self.loadResult = result
        self.pageCount = Int(ceil(Double(result.count) / Double(entriesPerPage)))
        if resetPage {
            self.currentPage = 0
        }
        self.onPageChanged()
    }
    
    func onPageChanged() {
        if let convertTask {
            convertTask.cancel()
            self.convertTask = nil
        }
        guard let loadResult else { return }
        
        let start = currentPage * entriesPerPage
        let end = min(start + entriesPerPage, loadResult.count)
        self.resources = nil
        convertTask = .detached {
            do {
                let resources = try loadResult[start..<end]
                    .map {
                        try Task.checkCancellation()
                        return ResourceDisplayModel($0.0, $0.1)
                    }
                await MainActor.run {
                    self.resources = resources
                }
            } catch let error where error.isCancellationError {
            } catch {
                err("刷新资源列表失败：\(error.localizedDescription)")
            }
            await MainActor.run {
                self.convertTask = nil
            }
        }
    }
    
    func toggleDisabled(_ resource: ResourceDisplayModel) throws {
        let newURL: URL
        if resource.disabled {
            newURL = resource.url.deletingPathExtension()
            log("正在启用资源 \(resource.fileName)")
        } else {
            newURL = resource.url.appendingPathExtension("disabled")
            log("正在禁用资源 \(resource.fileName)")
        }
        try FileManager.default.moveItem(at: resource.url, to: newURL)
        resource.disabled.toggle()
        resource.url = newURL
    }
    
    func loadInfo(for resource: ResourceDisplayModel) async throws -> ProjectListItemModel? {
        for source in resource.sources {
            if case .modrinth(let projectId) = source {
                do {
                    let project = try await ModrinthAPIClient.shared.project(projectId)
                    return .init(project)
                } catch {
                    throw SimpleError("查询 Modrinth Project 失败：\(error.localizedDescription)")
                }
            }
        }
        return nil
    }
    
    
    private func loadMods(of instance: MinecraftInstance) async throws -> [URL: Resource] {
        let service = ResourceLoadService(remoteLookupService: remoteLookupService, cache: cache)
        if instance.modLoader == nil {
            await MainActor.run {
                supportMods = false
            }
            throw SimpleError("该实例不支持模组。")
        }
        
        let modsDirectory = instance.url.appending(path: "mods")
        return try await service.loadResources(in: modsDirectory)
    }
}
