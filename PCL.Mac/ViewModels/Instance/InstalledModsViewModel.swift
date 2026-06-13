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
    @Published public var resources: [ResourceDisplayModel]?
    @Published public var supportMods: Bool = true
    @Published public var currentRepositoryId: UUID
    @Published public var currentPage: Int = 0
    @Published public var pageCount: Int = 0
    private var cancellables: Set<AnyCancellable> = []
    private var loadResult: [(URL, Mod)]?
    private var convertTask: Task<Void, Never>?
    private let instanceManager: InstanceManager
    private let id: String
    private let service: ModLoadService
    private let entriesPerPage: Int = 20
    
    init(instanceManager: InstanceManager, id: String) {
        self.instanceManager = instanceManager
        self.id = id
        self.currentRepositoryId = instanceManager.currentRepositoryId
        self.service = .init(
            remoteLookupService: .init(
                curseforgeClient: .init(apiKey: Secrets.shared.curseforgeApiKey ?? "")
            ),
            cache: .shared
        )
        
        instanceManager.$currentRepositoryId
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentRepositoryId, on: self)
            .store(in: &cancellables)
    }
    
    func load(resetPage: Bool = true) async throws {
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
        let result: [(URL, Mod)] = try await service.loadMods(in: modsDirectory)
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
}
