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
     * Add object to realm within a write transaction if necessary
     */
    func addToRealm(realm: RLMRealm = RLMRealm.defaultRealm()) {
        // Add to the Realm inside a transaction
        let transact = !realm.inWriteTransaction
        if transact {
            realm.beginWriteTransaction()
        }
        realm.addObject(self)
        if transact {
            realm.commitWriteTransaction()
        }
    }
    
    /**
     * Delete object from its Realm within a write transaction if necessary
     */
    func deleteFromRealm() {
        // Get the Realm
        if let realm = self.realm {
            let transact = !realm.inWriteTransaction
            if transact {
                realm.beginWriteTransaction()
            }
            // Remove from the Realm inside a transaction
            realm.deleteObject(self)
            if transact {
                realm.commitWriteTransaction()
            }
        }
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


var compressingRealm = false
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
    
    class func compress(ifNecessary: Bool = true) {
        compressingRealm = true
        
        let defaultPath = defaultRealmPath()
        var sizeError: NSError? = nil
        if let
            attributes = NSFileManager.defaultManager().attributesOfItemAtPath(defaultPath, error: &sizeError),
            size = attributes[NSFileSize] as? Int
            where size < 100*1024*1024 // 100 mb
        {
            return
        }
        
        var error: NSError? = nil
        let tempPath = defaultPath + "_copy"
        NSFileManager.defaultManager().removeItemAtPath(tempPath, error: nil)
        RLMRealm.defaultRealm().writeCopyToPath(tempPath, error: &error)
        println(error)
        RLMRealm.deleteDefaultRealmFile()
        let version = UInt(REALM_SCHEMA_VERSION)
        RLMRealm.setSchemaVersion(UInt64(version), forRealmAtPath: tempPath) { migration, oldSchemaVersion in }
        let tempRealm = RLMRealm(path: tempPath)
        tempRealm.writeCopyToPath(defaultPath, error: &error)
        println(error)
        NSFileManager.defaultManager().removeItemAtPath(tempPath, error: &error)
        println(error)
        
        compressingRealm = false
    }
}
