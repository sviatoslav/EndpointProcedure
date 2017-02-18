//
//  ElementsContainer.swift
//  EndpointProcedure
//
//  Created by Sviatoslav Yakymiv on 2/18/17.
//  Copyright © 2017 Sviatoslav Yakymiv. All rights reserved.
//

import Foundation

protocol ElementsContainer {
    static var elementType: Any.Type { get }
}

extension Array: ElementsContainer {
    static var elementType: Any.Type {
        return Element.self
    }
}

