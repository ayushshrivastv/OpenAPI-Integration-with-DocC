//
//  Result+Value.swift
//  
//
//  Created by Mathew Polzin on 6/28/19.
//

public extension Result {
    var value: Success? {
        switch self {
        case .success(let value):
            return value
        default:
            return nil
        }
    }

    var error: Failure? {
        switch self {
        case .failure(let error):
            return error
        default:
            return nil
        }
    }
}
