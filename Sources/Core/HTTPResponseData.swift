//
//  HTTPResponseData.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 1/10/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation

/// Typical result of HTTP data loading procedure
public struct HTTPResponseData {
    /// `HTTPURLResponse`
    public let urlResponse: HTTPURLResponse?
    /// Response `Data`
    public let data: Data

    /// Creates `HTTPResponseData`
    /// - parameters:
    ///     - urlResponse: `HTTPURLResponse`
    ///     - data: `Data`
    public init(urlResponse: HTTPURLResponse?, data: Data) {
        self.urlResponse = urlResponse
        self.data = data
    }
}
