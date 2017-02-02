//
//  CoreDataStack.swift
//  BooksApp
//
//  Created by Adrian McDaniel on 2/1/17.
//  Copyright © 2017 dssafsfsd. All rights reserved.
//


import Foundation
import CoreData

class CoreDataStack {
    
    
    //Get the managedObjectModel from Disk
    let managedObjectModelName: String
    
    required init(modelName: String) {
        managedObjectModelName = modelName
    }
    
    fileprivate lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL =
            Bundle.main.url(forResource: self.managedObjectModelName,
                            withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    fileprivate var applicationDocumentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory,
                                            in: .userDomainMask)
        return urls.first!
    }()
    
    //Needs the managedObjectModel to get objects out of the PersistentStore
    fileprivate lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        
        var coordinator =
            NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        let pathComponent = "\(self.managedObjectModelName).sqlite"
        let url =
            self.applicationDocumentsDirectory.appendingPathComponent(pathComponent)
        
        let store = try! coordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                        configurationName: nil,
                                                        at: url,
                                                        options: nil)
        
        return coordinator
    }()
    //Every Managed Object Context is a staging area.  If you don't save it will go away
    lazy var mainQueueContext: NSManagedObjectContext = {
        
        let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.persistentStoreCoordinator = self.persistentStoreCoordinator
        moc.name = "Main Queue Context (UI Context)"
        
        return moc
    }()
    //privateCont
    lazy var privateQueueContext: NSManagedObjectContext = {
        
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.parent = self.mainQueueContext
        moc.name = "Primary Private Queue Context"
        
        return moc
    }()
    
    func saveChanges() throws {
        var optionalError: Error?
        //typically do privateQueue first because you want things going on in the background
        privateQueueContext.performAndWait { () -> Void in
            if self.privateQueueContext.hasChanges {
                do {
                    try self.privateQueueContext.save()
                }
                catch let saveError {
                    optionalError = saveError
                }
            }
        }
        
        if let error = optionalError {
            throw error
        }
        
        mainQueueContext.performAndWait { () -> Void in
            
            if self.mainQueueContext.hasChanges {
                do {
                    try self.mainQueueContext.save()
                }
                catch let saveError {
                    optionalError = saveError
                }
            }
        }
        if let error = optionalError {
            throw error
        }
    }
    
}
