//
//  CoreData~PersistentContainer.swift
//
//  Created by Yauhen Rusanau on 6/19/20.
//

import Foundation
import CoreData

class PersitentConainer: NSPersistentContainer {
    // static let groupIdentifier = "group."

    override class func defaultDirectoryURL() -> URL {
        // FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) ?? super.defaultDirectoryURL()
        super.defaultDirectoryURL()
    }
}

extension PersitentConainer {
    static func storeUrl(modelName: String) -> URL {
        URL(fileURLWithPath: "\(modelName).sqlite", relativeTo: defaultDirectoryURL())
    }
}
