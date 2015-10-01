//
//  chainable.swift
//  amp-client
//
//  Created by Johannes Schriewer on 16.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation

public class AMPChainable<TKey: Hashable, TReturn> {

    var tasks: [TKey: (TKey -> Void)] = [:] // better?
    var callbacks: [(identifier: TKey, block: (TReturn -> Void))]  = [] // this way because of generics
    var errorCallbacks: [(AMPError.Code -> Void)]                  = [] // ^^^
    
    var isReady:Bool                                 = false
    
    // kv observer to automatically call all error callback as soon as an error is set
    var error:AMPError.Code? = nil {
        didSet {
            print("AMP: Error \(self.error)")
            self.callCallbacks(nil, value: nil, error: self.error)
        }
    }
    
    /// Append a task to the queue
    ///
    /// - Parameter identifier: task identifier, used to avoid queueing the same task twice
    /// - Parameter block: the task block
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

    /// Execute queued tasks
    func executeTasks() {
        // make a copy of the tasklist and remove all tasks from the global list
        let taskList = self.tasks
        self.tasks.removeAll()
        
        // run the tasks
        var tasks = taskList.generate()
        while let (identifier, task) = tasks.next() {
            task(identifier)
        }
    }
    
    /// Run callbacks that have been queued
    ///
    /// - Parameter identifier: the identifier of the callbacks to run (if set `error` is ignored)
    /// - Parameter value: value to submit with the callback (if set `error` is ignored)
    /// - Parameter error: an error to call the error callbacks for (if set `identifier` and `value` are ignored)
    func callCallbacks(identifier: TKey?, value: TReturn?, error: AMPError.Code?) {
        if let v = value {
            // filter identifier from callback list and call the callbacks in process
            self.callbacks = self.callbacks.filter({ (currentIdentifier: TKey, block: (TReturn -> Void)) -> Bool in
                if currentIdentifier == identifier! {
                    dispatch_async(AMP.config.responseQueue) {
                        block(v)
                    }
                    return false
                }
                return true
            })
        }
        
        if let e = error {
            for callback in errorCallbacks {
                dispatch_async(AMP.config.responseQueue) {
                    callback(e)
                }
            }
        }
    }
}
