//
//  Result+Extensions.swift
//  Baymax
//
//  Created by Ben Shutt on 18/06/2021.
//  Copyright © 2021 3 SIDED CUBE. All rights reserved.
//

import Foundation

public extension Result {

    /// Returns the associated value if the result is a success, `nil` otherwise.
    var success: Success? {
        guard case let .success(value) = self else { return nil }
        return value
    }

    /// Returns the associated error value if the result is a failure, `nil` otherwise.
    var failure: Failure? {
        guard case let .failure(error) = self else { return nil }
        return error
    }
}

// MARK: - Result + Error
public extension Result where Failure == Error {

    /// Initialize a `Result` with the `throwable` closure
    ///
    /// - Parameter throwable: Closure which may `throw`
    init(_ throwable: () throws -> Success) {
        do {
            self = try .success(throwable())
        } catch {
            self = .failure(error)
        }
    }
}
