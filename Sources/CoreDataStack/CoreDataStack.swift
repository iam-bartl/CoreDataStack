//
//  CoreData~Setup.swift
//
//  Created by Yauhen Rusanau on 6/19/20.
//

import Foundation
import CoreData

public final class CoreDataStack {
    public enum Mode {
        case `default`
        case memory
    }

    private let container: NSPersistentContainer

    public init(mode: Mode = .default, modelName: String, bundle: Bundle, model: NSManagedObjectModel? = nil) {
        guard let storeModel = model ?? .named(modelName, bundle: bundle) else {
            fatalError("Provide data model!")
        }
        
        container = PersitentConainer(name: modelName, managedObjectModel: storeModel)

        if mode == .memory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            description.shouldAddStoreAsynchronously = false // Make it simpler in test env
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { (_, error) in
            if let error = error { fatalError("Can't load persistence: \(error.localizedDescription)") }
        }

        background = container.newBackgroundContext()
    }

    public func performBackground(_ work: @escaping (NSManagedObjectContext) -> Void) {
        background.perform { [weak background] in
            guard let ctx = background else { return }
            work(ctx)
        }
    }

    func managedObjectID(for identifier: String) -> NSManagedObjectID? {
        container.persistentStoreCoordinator.objectId(for: identifier)
    }

    let background: NSManagedObjectContext
}

extension NSPersistentStoreCoordinator {
    func objectId(for identifier: String) -> NSManagedObjectID? {
        guard let url = URL(string: identifier) else { return nil }
        return managedObjectID(forURIRepresentation: url)
    }
}
