//
//  chainable.swift
//  amp-client
//
//  Created by Johannes Schriewer on 16.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation

public class AMPChainable<TKey: Hashable, TReturn> {
    var tasks:Dictionary<TKey, (TKey -> Void)>                               = Dictionary<TKey, (TKey -> Void)>()
    var callbacks:Array<(identifier: TKey, block: (TReturn -> Void))>        = []
    var errorCallbacks:Array<(ErrorType -> Void)>                            = []
    
    var isReady:Bool                                 = false
    var error:AMPError.Code? = nil {
        didSet {
            self.callCallbacks(nil, value: nil, error: self.error)
        }
    }
    
    func appendTask(identifier: TKey, block: (TKey -> Void)) {
        if self.tasks[identifier] != nil {
            // Task already queued, do nothing
            return
        }
        // Add task to queue
        self.tasks.updateValue(block, forKey: identifier)
        
        // If we're ready already execute task directly
        if self.isReady {
            self.executeTasks()
        }
    }

    func executeTasks() {
        // Execute queued tasks
        let taskList = self.tasks
        self.tasks.removeAll()
        
        var tasks = taskList.generate()
        while let (identifier, task) = tasks.next() {
            task(identifier)
        }
    }
    
    func callCallbacks(identifier: TKey?, value: TReturn?, error: ErrorType?) {
        if let v = value {
            // filter identifier from callback list and call the callbacks in process
            self.callbacks = self.callbacks.filter({ (currentIdentifier: TKey, block: (TReturn -> Void)) -> Bool in
                if currentIdentifier == identifier! {
                    block(v)
                    return false
                }
                return true
            })
        }
        
        if let e = error {
            for callback in errorCallbacks {
                callback(e)
            }
        }
    }
}
