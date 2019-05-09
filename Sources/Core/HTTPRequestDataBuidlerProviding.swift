//
//  HTTPRequestDataBuidlerProvider.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 9/30/18.
//  Copyright © 2018 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation

public protocol HTTPRequestDataBuidlerProviding {
    func builder(for path: String) throws -> HTTPRequestData.Builder
}

public protocol BaseURLProviding {
    var baseURL: URL { get }
}

public extension HTTPRequestDataBuidlerProviding where Self: BaseURLProviding {
    func builder(for path: String) throws -> HTTPRequestData.Builder {
        guard let builder = URL(string: path, relativeTo: self.baseURL).map(HTTPRequestData.Builder.for) else {
            throw HTTPRequestData.Builder.Error.unableToCreateURL
        }
        return builder
    }
}
