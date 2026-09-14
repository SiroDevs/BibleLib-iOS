//
//  CoreDataManager.swift
//  BibleLib
//
//  Same pattern as SwahiLib's CoreDataManager, pointed at BibleLib's own
//  .xcdatamodeld.
//

import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()

    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "BibleLib")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("❌ Failed to load Core Data stack: \(error)")
            }
            if let dbPath = description.url?.path {
                print("📦 Core Data SQLite DB path:\n\(dbPath)")
            }
        }
        return container
    }()

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
}
