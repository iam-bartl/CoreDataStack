//
//  TypedObjectOperations.swift
//
//  Created by Yauhen Rusanau on 6/19/20.
//

import Foundation
import CoreData
import Combine
import Identifier

public protocol TypedManagedObject {
    static var entityName: String { get }

    associatedtype DomainType: HasIdentifier
    func assign(domain: DomainType)
    var domain: DomainType? { get }
}

public extension TypedManagedObject {
    static func entityDescription(in ctx: NSManagedObjectContext) -> NSEntityDescription {
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: ctx) else {
            fatalError("Incorrect entity name")
        }
        return entity
    }
    
    static func create(in ctx: NSManagedObjectContext) -> Self? {
        NSManagedObject(entity: entityDescription(in: ctx), insertInto: ctx) as? Self
    }
}

extension CoreDataStack {
    typealias Event<Element> = (Result<Element, Error>) -> Void

    func performBackgroundSingle<Result>(_ work: @escaping (NSManagedObjectContext, Event<Result>) -> Void) -> AnyPublisher<Result, Error> {
        Deferred {
            Future { promise in
                self.performBackground { ctx in work(ctx, promise) }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func performAsync<Result>(_ work: @escaping (NSManagedObjectContext) throws -> Result) async throws -> Result {
        try await withCheckedThrowingContinuation { continuation in
            performBackground { ctx in
                do {
                    let result = try work(ctx)
                    continuation.resume(with: .success(result))
                } catch {
                    continuation.resume(with: .failure(error))
                }
            }
        }
    }
}

public extension TypedManagedObject where Self: NSManagedObject, DomainType.RawIdentifier == String {
    var domainId: Identifier<DomainType> { .existing(objectID.uriRepresentation().absoluteString) }

    static func new(in ctx: NSManagedObjectContext) -> Self {
        Self(entity: Self.entityDescription(in: ctx), insertInto: ctx)
    }
    
    static func create(in stack: CoreDataStack, objects: [DomainType]) async throws -> [DomainType] {
        try await stack.performAsync { ctx in
            let managedObjects: [Self] = objects.map {
                let managed = Self.new(in: ctx)
                managed.assign(domain: $0)
                return managed
            }
            
            try ctx.save()
            
            return managedObjects.compactMap { $0.domain }
        }
    }

    static func fetch(in stack: CoreDataStack, objects: [Identifier<DomainType>]) async throws -> [DomainType] {
        let managed = try await fetchManaged(in: stack, objects: objects)
        return try await stack.performAsync { _ in
            managed.domain
        }
    }

    static func fetchManaged(in stack: CoreDataStack, objects: [Identifier<DomainType>]) async throws -> [Self] {
        try await stack.performAsync { ctx in
            let result: [Self] = objects.filter { !$0.isNew }.compactMap { ctx.existing(with: $0) }
            return result
        }
    }
    
    static func fetch(
        in stack: CoreDataStack,
        predicate: NSPredicate?,
        sort: [NSSortDescriptor]? = nil,
        fetchOffset: Int = 0,
        fetchLimit: Int = 0
    ) async throws -> [DomainType] {
        let managed = try await fetchManaged(
            in: stack,
            predicate: predicate,
            sort: sort,
            fetchOffset: fetchOffset,
            fetchLimit: fetchLimit
        )
        
        return try await stack.performAsync { _ in
            managed.domain
        }
    }
    
    static func fetchManaged(
        in stack: CoreDataStack,
        predicate: NSPredicate?,
        sort: [NSSortDescriptor]? = nil,
        fetchOffset: Int = 0,
        fetchLimit: Int = 0
    ) async throws -> [Self] {
        try await stack.performAsync { ctx in
            let request = NSFetchRequest<Self>()
            request.entity = Self.entityDescription(in: ctx)
            request.predicate = predicate
            request.sortDescriptors = sort
            request.fetchOffset = fetchOffset
            request.fetchLimit = fetchLimit
            request.includesPropertyValues = true
            
            return try request.execute()
        }
    }
    
    static func fetchCount(in stack: CoreDataStack, predicate: NSPredicate? = nil) async throws -> Int {
        try await stack.performAsync { ctx in
            let request = NSFetchRequest<Self>()
            request.entity = Self.entityDescription(in: ctx)
            request.predicate = predicate
            
            let result = try ctx.count(for: request)
            
            return result
        }
    }
    
    static func update(in stack: CoreDataStack, objects: [DomainType]) async throws -> [DomainType] {
        let managed = try await fetchManaged(in: stack, objects: objects.map { $0.id })
        let updated = try await updateManaged(in: stack, managed: managed, with: objects)
        return updated
    }
    
    static func updateManaged(in stack: CoreDataStack, managed: [Self], with objects: [DomainType]) async throws -> [DomainType] {
        try await stack.performAsync { ctx in
            objects.forEach { obj in
                managed.first(where: { obj.id == $0.domainId })?
                .assign(domain: obj) }
            try ctx.save()
            
            return managed.compactMap { $0.domain }
        }
    }
    
    static func delete(in stack: CoreDataStack, objects: [Identifier<DomainType>]) async throws {
        let managed = try await fetchManaged(in: stack, objects: objects)
        try await deleteManaged(in: stack, managed: managed)
    }

    static func deleteManaged(in stack: CoreDataStack, managed: [Self]) async throws {
        try await stack.performAsync { ctx in
            managed.forEach { ctx.delete($0) }
            try ctx.save()
        }
    }
}

public extension Array where Element: TypedManagedObject {
    var domain: [Element.DomainType] { compactMap { $0.domain } }
}

public extension Set where Element: TypedManagedObject {
    var domain: [Element.DomainType] { Array(self).domain }
}
