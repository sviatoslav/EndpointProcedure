//
//  DefaultConfigurationProvider.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 9/30/18.
//  Copyright © 2018 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation

public protocol DefaultConfigurationProvider {
    var defaultConfiguration: ConfigurationProtocol { get }
}

public extension EndpointProcedureFactory where Self: DefaultConfigurationProvider {
    func create() -> EndpointProcedure<Result> {
        return self.create(with: self.defaultConfiguration)
    }
}
