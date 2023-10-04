//
//  NSManagedObjectModel+Helpers.swift
//  
//
//  Created by Yauhen Rusanau on 6/1/21.
//

import Foundation
import CoreData

extension NSManagedObjectModel {
    static func named(_ modelName: String, bundle: Bundle) -> NSManagedObjectModel? {
        URL.modelUrl(modelName, bundle: bundle).flatMap { NSManagedObjectModel(contentsOf: $0) }
    }

    static func modelVersions(modelName: String, bundle: Bundle) -> [NSManagedObjectModel] {
        modelURLs(modelName: modelName, bundle: bundle)
            .compactMap(NSManagedObjectModel.init)
    }
}

private extension NSManagedObjectModel {
    static func modelURLs(modelName: String, bundle: Bundle) -> [URL] {
        (bundle.urls(forResourcesWithExtension: "mom", subdirectory: "\(modelName).momd") ?? [])
            .sorted(by: { URL.compareModelUrls($0, right: $1) })
    }
}

private extension URL {
    static func modelUrl(_ modelName: String, bundle: Bundle) -> URL? {
        bundle.url(forResource: modelName, withExtension: "momd")
    }

    static func compareModelUrls(_ left: URL, right: URL) -> Bool {
        let leftLastPath = left.lastPathComponent.replacingOccurrences(of: ".mom", with: "")
        let rightLastPath = right.lastPathComponent.replacingOccurrences(of: ".mom", with: "")

        let leftComponens = leftLastPath.components(separatedBy: " ")
        let rightComponens = rightLastPath.components(separatedBy: " ")

        guard leftComponens.count > 1, rightComponens.count > 1 else { return leftComponens.count < rightComponens.count }

        return Int(leftComponens[1]) ?? 0 < Int(rightComponens[1]) ?? 0
    }
}
