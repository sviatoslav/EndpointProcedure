//
//  HTTPResponseData.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 1/10/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation

public struct HTTPResponseData {
    public let urlResponse: HTTPURLResponse?
    public let data: Data

    public init(urlResponse: HTTPURLResponse?, data: Data) {
        self.urlResponse = urlResponse
        self.data = data
    }
}
