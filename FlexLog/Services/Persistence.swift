//
//  Persistence.swift
//  FlexLog
//
//  Created by Вадим Дзюба on 01.10.2025.
//

import CoreData

@objc(FlexArrayTransformer)
private final class FlexArrayTransformer: ValueTransformer {
    override class func allowsReverseTransformation() -> Bool { true }

    override class func transformedValueClass() -> AnyClass {
        NSData.self
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let array = value as? [String] else { return nil }
        return try? JSONEncoder().encode(array)
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        return try? JSONDecoder().decode([String].self, from: data)
    }
}

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        viewContext.performAndWait {
            // Populate preview context with minimal sample data if needed
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        self.container = NSPersistentContainer(name: "FlexLog")
        ValueTransformer.setValueTransformer(FlexArrayTransformer(), forName: NSValueTransformerName("FlexArrayTransformer"))
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
