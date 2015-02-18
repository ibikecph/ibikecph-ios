//
//  Realm.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 16/02/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

//import Realm

extension RLMObject {
    
    /**
     * Add object to realm within a write transaction
     */
    func addToRealm(realm: RLMRealm = RLMRealm.defaultRealm()) {
        // Add to the Realm inside a transaction
        realm.beginWriteTransaction()
        realm.addObject(self)
        realm.commitWriteTransaction()
    }
    
    /**
     * Delete object from its Realm within a write transaction
     */
    func deleteFromRealm() {
        // Get the Realm
        if let realm = self.realm {
            // Remove from the Realm inside a transaction
            realm.beginWriteTransaction()
            realm.deleteObject(self)
            realm.commitWriteTransaction()
        }
    }
}

extension RLMArray {
    
    /**
     * Add object to array within a write transaction
     */
    func add(object: RLMObject) {
        
        realm.beginWriteTransaction()
        
        // Add object to realm
        realm.addObject(object)
        
        // Add to array
        self.addObject(object)
        
        realm.commitWriteTransaction()
        
        // Add to the Realm inside a transaction
//        self.realm.addObject(object)
        
        
    }
}

extension RLMRealm {
    
    class func deleteDefaultRealmFile() {
        var path = defaultRealmPath()
        NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
    }
    
    class func addNotificationBlock(block: RLMNotificationBlock) -> RLMNotificationToken {
        return RLMRealm.defaultRealm().addNotificationBlock(block)
    }
}
