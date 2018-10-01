//
//  HTTPRequestDataBuidlerProvider.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 9/30/18.
//  Copyright © 2018 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation

public protocol HTTPRequestDataBuidlerProvider {
    func builder(for path: String) throws -> HTTPRequestData.Builder
}

public protocol BaseURLProvider {
    var baseURL: URL { get }
}

public extension HTTPRequestDataBuidlerProvider where Self: BaseURLProvider {
    func builder(for path: String) throws -> HTTPRequestData.Builder {
        guard let builder = URL(string: path, relativeTo: self.baseURL).map(HTTPRequestData.Builder.for) else {
            throw HTTPRequestData.Builder.Error.unableToCreateURL
        }
        return builder
    }
}
