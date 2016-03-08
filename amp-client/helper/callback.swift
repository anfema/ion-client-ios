//
//  callback.swift
//  amp-client
//
//  Created by Dominik Felber on 08.03.16.
//  Copyright © 2016 anfema. All rights reserved.
//

import Foundation
import Alamofire


/// Performs the callback in the responseQueue defined in AMP.config.responseQueue
/// 
/// - parameter callback:  The callback that will be called.
/// - parameter parameter: The parameter of the callback.
func responseQueueCallback <T, U> (callback: T -> U, parameter: T) {
    dispatch_async(AMP.config.responseQueue) {
        callback(parameter)
    }
}



/// Performs the callback in the responseQueue defined in AMP.config.responseQueue
///
/// - parameter callback:  The callback that will be called if not nil.
/// - parameter parameter: The parameter of the callback.
func responseQueueCallback <T, U> (callback: (T -> U)?, parameter: T) {
    guard let callback = callback else {
        return
    }
    
    responseQueueCallback(callback, parameter: parameter)
}