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
        guard case .success(let value) = self else {
            return nil
        }
        return value
    }
}

//extension Swift.Result
//{
//    static func makeFrom(result: Alamofire.Result<Value>)
//    {
//        switch result
//        {
//        case
//        }
//    }
//    init(result: Alamofire.Result<Success>)
//    {
//        switch result {
//        case .success(let data):
//            self = .success(data)
//        case .failure(let error):
//            self = .failure(error as! Failure)
//        }
//    }
//}
