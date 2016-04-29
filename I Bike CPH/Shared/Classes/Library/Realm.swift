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
            do {
                try realm.commitWriteTransaction()
            } catch {
                print("Could not commit Realm write transaction!")
            }
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
                do {
                    try realm.commitWriteTransaction()
                } catch {
                    print("Could not commit Realm write transaction!")
                }
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

extension RLMArray {
    
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
        if let fileURL = RLMRealmConfiguration.defaultConfiguration().fileURL {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(fileURL)
            } catch {
                print("Couldn't delete Realm file!")
            }
        }
    }
    
    class func addNotificationBlock(block: RLMNotificationBlock) -> RLMNotificationToken {
        return RLMRealm.defaultRealm().addNotificationBlock(block)
    }
    
    class func removeNotification(token: RLMNotificationToken) {
        token.stop()
    }
    
    class func beginWriteTransaction() {
        return RLMRealm.defaultRealm().beginWriteTransaction()
    }
    class func commitWriteTransaction() {
        do {
            try RLMRealm.defaultRealm().commitWriteTransaction()
        } catch {
            print("Could not commit Realm write transaction!")
        }
    }
    
    class func compress(ifNecessary: Bool = true) {
        if let defaultFileURL = RLMRealmConfiguration.defaultConfiguration().fileURL,
               defaultPath = defaultFileURL.path {
            if let
                attributes = try? NSFileManager.defaultManager().attributesOfItemAtPath(defaultPath),
                size = attributes[NSFileSize] as? Int
                where size < 100*1024*1024 // 100 mb
            {
                return
            }
            compressingRealm = true
            
            let tempFileURL = NSURL.fileURLWithPath(defaultPath + "_copy")
            do {
                try NSFileManager.defaultManager().removeItemAtURL(tempFileURL)
                try RLMRealm.defaultRealm().writeCopyToURL(tempFileURL, encryptionKey: nil)
                try NSFileManager.defaultManager().removeItemAtURL(defaultFileURL)
                try NSFileManager.defaultManager().moveItemAtURL(tempFileURL, toURL: defaultFileURL)
            } catch {
                print("Realm file swapping failed!")
            }
            RLMRealm.defaultRealm()
            compressingRealm = false
        }
    }
}
