//
//  Thread.swift
//  I Bike CPH
//
//  Created by Tobias Due Munk on 22/05/15.
//  Copyright (c) 2015 I Bike CPH. All rights reserved.
//

import UIKit

class Thread: Foundation.Thread {
    
    typealias Block = () -> ()
    
    fileprivate let queueCondition = NSCondition()
    fileprivate var blockQueue = [Block]()
    
    override func main() {
        
        while true {
            queueCondition.lock()
            while (blockQueue.count == 0 && !isCancelled) {
                queueCondition.wait()
            }
            
            if (isCancelled) {
                queueCondition.unlock()
                return
            }
        
            let block = blockQueue.remove(at: 0)
            queueCondition.unlock()
            
            // Execute block outside the condition, since it's also a lock!
            // We want to give other threads the possibility to enqueue
            // a new block while we're executing a block.
            block()
        }
    }
    
    func enqueue(_ block: @escaping Block) {
        queueCondition.lock()
        blockQueue.append(block)
        queueCondition.signal()
        queueCondition.unlock()
    }
    
    func stopThread() {
        queueCondition.lock()
        cancel()
        queueCondition.signal()
        queueCondition.unlock()
    }
}
