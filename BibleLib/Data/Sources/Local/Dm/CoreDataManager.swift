//
//  CoreDataManager.swift
//  BibleLib
//
//  Created by @sirodevs on 12/09/2026.
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
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()

    lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
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
