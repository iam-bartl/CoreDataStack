//
//  MigrationManager.swift
//  
//
//  Created by Yauhen Rusanau on 6/1/21.
//

import Foundation
import CoreData

final class MigrationManager {
    var stack: CoreDataStack {
        if !storeIsCompatible(with: currentModel) {
            performMigrations()
        }
        return .init(modelName: modelName, bundle: bundle, model: currentModel)
    }

    private let storeUrl: URL
    private let modelName: String
    private let bundle: Bundle
    private lazy var currentModel: NSManagedObjectModel = {
        guard let model = NSManagedObjectModel.named(modelName, bundle: bundle) else {
            fatalError("Can't load current CoreData model")
        }
        return model
    }()

    init(modelName: String, bundle: Bundle) {
        self.modelName = modelName
        self.bundle = bundle
        self.storeUrl = PersitentConainer.storeUrl(modelName: modelName)
    }
}

private extension MigrationManager {
    func performMigrations() {
        let models = NSManagedObjectModel.modelVersions(modelName: modelName, bundle: bundle)
        guard let lastCompatibleIndex = models.firstIndex(where: { storeIsCompatible(with: $0) }) else {
            fatalError("Can't find last compatible model version")
        }

        (lastCompatibleIndex..<models.count-1).forEach {
            let mappingModel = NSMappingModel(from: [bundle],
                                              forSourceModel: models[$0],
                                              destinationModel: models[$0+1])

            do {
                try migrate(from: models[$0], to: models[$0+1], mappingModel: mappingModel)
            }
            catch {
                fatalError("Can't migrate from \($0): \(error)")
            }
        }
    }

    func migrate(from sourceModel: NSManagedObjectModel,
                 to destinationModel: NSManagedObjectModel,
                 mappingModel: NSMappingModel?) throws {

        guard let migrationMappingModel = mappingModel ??
                (try? NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: destinationModel))
        else { fatalError("Can't infer mapping model") }

        let directory = storeUrl.deletingLastPathComponent()
        let target = directory.appendingPathComponent(storeUrl.lastPathComponent + "~migrating")

        let migrationManager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
        try migrationManager.migrateStore(from: storeUrl,
                                          sourceType: NSSQLiteStoreType,
                                          options: nil,
                                          with: migrationMappingModel,
                                          toDestinationURL: target,
                                          destinationType: NSSQLiteStoreType,
                                          destinationOptions: nil)

        let oldStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: sourceModel)
        try oldStoreCoordinator.destroyPersistentStore(at: storeUrl, ofType: NSSQLiteStoreType, options: nil)

        let migratedStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: destinationModel)
        try migratedStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                        configurationName: nil,
                                                        at: target,
                                                        options: nil)

        try migratedStoreCoordinator.migratePersistentStore(migratedStoreCoordinator.persistentStores[0],
                                                            to: storeUrl,
                                                            options: nil,
                                                            withType: NSSQLiteStoreType)
        try migratedStoreCoordinator.destroyPersistentStore(at: target, ofType: NSSQLiteStoreType, options: nil)
    }

    func storeIsCompatible(with model: NSManagedObjectModel) -> Bool {
        guard FileManager.default.fileExists(atPath: storeUrl.path) else { return true }
        let storeMetadata = metadataForStoreAtURL(storeURL: storeUrl)
        return model.isConfiguration(withName: nil, compatibleWithStoreMetadata: storeMetadata)
    }

    private func metadataForStoreAtURL(storeURL: URL) -> [String: Any] {
        let metadata: [String: Any]
        do {
            metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType,
                                                                                   at: storeURL,
                                                                                   options: nil)
        }
        catch {
            metadata = [:]
            // Log.error(error, component: "MigrationManager", level: .nonFatal)
        }
        return metadata
    }
}
