//
//  AsyncResult.swift
//  ion-client
//
//  Created by Dominik Felber, Matthias Redlin on 23.02.17.
//  Copyright © 2017 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)


import Foundation

/// Used to represent whether a operation was successful or encountered an error.
///
/// - Success: The operation and all post processing operations were successful resulting in the
///            provided associated value.
/// - Failure: The request encountered an error resulting in a failure. The associated values is an error that caused the failure.
public class AsyncResult<T> {
    
    private var success: ((T) -> Void)?
    
    private var failure: ((Error) -> Void)?

    
    /// Handler that should be triggered on a successfull operation
    /// You can attach a onFailure handler right after the onSuccess handler
    @discardableResult public func onSuccess (_ success: @escaping (T) -> Void) -> AsyncResult {
        self.success = success
        return self
    }

    
    /// Handler that should be triggered on a failed operation
    @discardableResult public func onFailure (_ failure: @escaping (Error) -> Void) -> AsyncResult {
        self.failure = failure
        return self
    }

    
    /// Executes the success or failure handler based on the provided Result
    func execute(result: Result<T>) {
        guard case .success(let value) = result else {
            failure?(result.error ?? IONError.didFail)
            return
        }

        success?(value)
    }

    
    deinit {
        success = nil
        failure = nil
    }
}
