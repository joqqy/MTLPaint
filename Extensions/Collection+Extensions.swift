//
//  Collection+Extensions.swift
//  BigBrush
//
//  Created by Pierre Hanna on 2018-09-27.
//  Copyright © 2018 Pierre Hanna. All rights reserved.
//

import Foundation

extension Collection where Element: Hashable {
    
    var orderedSet: [Element] {
        
        var set: Set<Element> = []
        return reduce(into: []) { set.insert($1).inserted ? $0.append($1) : () }
    }
}

