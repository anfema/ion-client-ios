//
//  chainable.swift
//  amp-client
//
//  Created by Johannes Schriewer on 16.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation

private class AMPCallstack<T> {
    private var errorCallback:(AMPError.Code -> Void)? = nil
    private var callbacks:[(identifier: String, block: (T -> Void))] = []
    
    let callbackLock = NSRecursiveLock()
    
    var queuedIdentifiers:[String] {
        get {
            var identifiers:[String] = []
            self.callbackLock.lock()
            for callback in self.callbacks {
                identifiers.append(callback.identifier)
            }
            self.callbackLock.unlock()
            return identifiers
        }
    }

    init(errorCallback: (AMPError.Code -> Void)?) {
        self.errorCallback = errorCallback
    }
    
    func appendCallback(identifier: String, callback: (T -> Void)) {
        self.callbackLock.lock()
        self.callbacks.append((identifier, callback))
        self.callbackLock.unlock()
    }
    
    func callCallbacks(identifier: String, value: T?, error: AMPError.Code?) {
        // filter identifier from callback list and call the callbacks in process
        self.callbackLock.lock()
        self.callbacks = self.callbacks.filter { (currentIdentifier: String, block: (T -> Void)) -> Bool in
            if currentIdentifier == identifier {
                if let v = value {
                    // if there's a value call the block
                    block(v)
                }
                
                if let e = error, let callback = self.errorCallback {
                    // if there's an error and an error callback call it
                    callback(e)
                }

                // remove callback from list
                return false
            }
            
            // this callback stays in list as it is unrelated to identifier
            return true
        }
        self.callbackLock.unlock()
    }
}

public class AMPChainable<TReturn> {
    var tasks: [String: (String -> Void)]         = [:]
    private var callStack:[AMPCallstack<TReturn>] = []
    var isReady:Bool                              = false
    var hasFailed:Bool                            = false
    
    let callStackLock = NSRecursiveLock()
    
    /// Append a task to the queue
    ///
    /// - Parameter identifier: task identifier, used to avoid queueing the same task twice
    /// - Parameter block: the task block
    func appendTask(identifier: String, deduplicate: Bool = true, block: (String -> Void)) {
        if deduplicate {
            if self.tasks[identifier] == nil {
                // Add task to queue
                self.tasks.updateValue(block, forKey: identifier)
            }
        } else {
            let modifiedKey = "\(identifier)-\(NSDate().timeIntervalSince1970 * 100000)"
            self.tasks.updateValue(block, forKey: modifiedKey)
        }
        
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
    
    func callError(identifier: String, error: AMPError.Code) {
        self.callCallbacks(identifier, value: nil, error: error)
    }
    
    func getQueuedIdentifiers() -> [String] {
        var identifiers:[String] = []
        self.callStackLock.lock()
        for item in callStack {
            identifiers.appendContentsOf(item.queuedIdentifiers)
        }
        self.callStackLock.unlock()
        return identifiers
    }
    
    // MARK: Stack handling
    func appendErrorCallback(callback: (AMPError.Code -> Void)?) {
        self.callStackLock.lock()
        self.callStack.append(AMPCallstack<TReturn>(errorCallback: callback))
        self.callStackLock.unlock()
    }
    
    func appendCallback(identifier: String, callback: (TReturn -> Void)) {
        self.callStackLock.lock()
        var callStack = self.callStack.last
        if callStack == nil {
            self.callStack.append(AMPCallstack<TReturn>(errorCallback: { error in
                self.defaultErrorCallback(error)
            }))
            callStack = self.callStack.last
        }
        self.callStackLock.unlock()
        callStack!.appendCallback(identifier, callback: callback)
    }
    
    func defaultErrorCallback(error: AMPError.Code) {
        // overridden by subclass if needed
    }
    
    /// Run callbacks that have been queued
    ///
    /// - Parameter identifier: the identifier of the callbacks to run (if set `error` is ignored)
    /// - Parameter value: value to submit with the callback (if set `error` is ignored)
    /// - Parameter error: an error to call the error callbacks for (if set `identifier` and `value` are ignored)
    func callCallbacks(identifier: String, value: TReturn?, error: AMPError.Code?) {
        self.callStackLock.lock()
        if (error != nil) && (self.callStack.count == 0) {
            self.defaultErrorCallback(error!)
        }
        self.callStack = self.callStack.filter { item -> Bool in
            item.callCallbacks(identifier, value: value, error: error)
            if item.callbacks.count == 0 {
                return false // remove this error handler from call stack as there are no further callbacks to call
            }
            return true
        }
        self.callStackLock.unlock()
    }
}
