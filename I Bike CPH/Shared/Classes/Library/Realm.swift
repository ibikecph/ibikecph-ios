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
    func addToRealm(_ realm: RLMRealm = RLMRealm.default()) {
        // Add to the Realm inside a transaction
        let transact = !realm.inWriteTransaction
        if transact {
            realm.beginWriteTransaction()
        }
        realm.add(self)
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
            realm.delete(self)
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

    func toArray<T>(_ ofType: T.Type) -> [T] {
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
        if let fileURL = RLMRealmConfiguration.default().fileURL {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("Couldn't delete Realm file!")
            }
        }
    }
    
    class func addNotificationBlock(_ block: RLMNotificationBlock) -> RLMNotificationToken {
        return RLMRealm.default().addNotificationBlock(block)
    }
    
    class func removeNotification(_ token: RLMNotificationToken) {
        token.stop()
    }
    
    class func beginWriteTransaction() {
        return RLMRealm.default().beginWriteTransaction()
    }
    class func commitWriteTransaction() {
        do {
            try RLMRealm.default().commitWriteTransaction()
        } catch {
            print("Could not commit Realm write transaction!")
        }
    }
    
    class func compress(_ ifNecessary: Bool = true) {
        if let defaultFileURL = RLMRealmConfiguration.default().fileURL,
               let defaultPath = defaultFileURL.path {
            if let
                attributes = try? FileManager.default.attributesOfItem(atPath: defaultPath),
                let size = attributes[FileAttributeKey.size] as? Int, size < 100*1024*1024 // 100 mb
            {
                return
            }
            compressingRealm = true
            
            let tempFileURL = URL(fileURLWithPath: defaultPath + "_copy")
            do {
                try FileManager.default.removeItem(at: tempFileURL)
                try RLMRealm.default().writeCopy(to: tempFileURL, encryptionKey: nil)
                try FileManager.default.removeItem(at: defaultFileURL)
                try FileManager.default.moveItem(at: tempFileURL, to: defaultFileURL)
            } catch {
                print("Realm file swapping failed!")
            }
            RLMRealm.default()
            compressingRealm = false
        }
    }
}
