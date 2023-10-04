//
//  NSManagedObjectContext.swift
//
//  Created by Yauhen Rusanau on 9/3/20.
//

import Foundation
import CoreData
import Identifier

extension NSManagedObjectContext {
    func existing<T: TypedManagedObject>(with id: Identifier<T.DomainType>) -> T? where T.DomainType.RawIdentifier == String {
        if case .existing(let identifier) = id,
            let managedIdentifier = persistentStoreCoordinator?.objectId(for: identifier) {
            return (try? existingObject(with: managedIdentifier)) as? T
        }
        else {
            return nil
        }
    }
}
