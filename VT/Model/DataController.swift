//
//  DataController.swift
//  VT
//
//  Created by Pablo Albuja on 6/29/20.
//  Copyright © 2020 Ingenuity Applications. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    let persistentContainer:NSPersistentContainer
    
    var viewContext:NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    var backgroundContext:NSManagedObjectContext!
    
    init(modelName:String){
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func configureContexts() {
        backgroundContext = persistentContainer.newBackgroundContext()
        
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    func load(completion: (() -> Void)? = nil){
        persistentContainer.loadPersistentStores{ storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.autoSaveViewContext()//default to 30s
            self.configureContexts()
            completion?()
            
        }
    }
}

extension DataController {
    func autoSaveViewContext(interval:TimeInterval = 30){
        print("auto-saving")
        guard interval > 0 else {
            print("What were you thinking with 0 or less seconds?")
            return
        }
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: {
            self.autoSaveViewContext(interval: interval)
        })
    }
}
