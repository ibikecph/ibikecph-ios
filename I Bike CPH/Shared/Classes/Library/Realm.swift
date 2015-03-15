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
    func addToRealm(realm: RLMRealm = RLMRealm.defaultRealm(), inWriteTransaction: Bool = true) {
        // Add to the Realm inside a transaction
        if inWriteTransaction {
            realm.beginWriteTransaction()
        }
        realm.addObject(self)
        if inWriteTransaction {
            realm.commitWriteTransaction()
        }
    }
    
    /**
     * Delete object from its Realm within a write transaction
     */
    func deleteFromRealm(inWriteTransaction: Bool = true) {
        // Get the Realm
        if let realm = self.realm {
            if inWriteTransaction {
                realm.beginWriteTransaction()
            }
            // Remove from the Realm inside a transaction
            realm.deleteObject(self)
            if inWriteTransaction {
                realm.commitWriteTransaction()
            }
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

extension RLMResults {
    
    func toArray() -> [RLMObject] {
        var array = [RLMObject]()
        for result in self {
            array.append(result)
        }
        return array
    }
    func toArray<T>(ofType: T.Type) -> [T] {
        var array = [T]()
        for result in self {
            if let result = result as? T {
                array.append(result)
            }
        }
        return array
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
    
    class func removeNotification(token: RLMNotificationToken?) {
        return RLMRealm.defaultRealm().removeNotification(token)
    }
    
    class func beginWriteTransaction() {
        return RLMRealm.defaultRealm().beginWriteTransaction()
    }
    class func commitWriteTransaction() {
        return RLMRealm.defaultRealm().commitWriteTransaction()
    }
}
