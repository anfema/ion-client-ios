//
//  resultextensions.swift
//  IONClient
//
//  Created by Matthias Redlin on 18.02.22.
//

import Foundation
import Alamofire

extension Swift.Result
{
    /// Returns the optional error in case of a failure.
    var error: Failure?
    {
        guard case let .failure(error) = self else { return nil }
        return error
    }
    
    func optional() -> Success?
    {
        guard case let .success(value) = self else {
            return nil
        }
        return value
    }
    
    var isFailure: Bool
    {
        return error != nil
    }
    
    var isSuccess: Bool
    {
        guard case .success = self else {
            return false
        }
        
        return true
    }
    
    var value: Success?
    {
        guard case let .success(value) = self else {
            return nil
        }
        
        return value
    }
}
