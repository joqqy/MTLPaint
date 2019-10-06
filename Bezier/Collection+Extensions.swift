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

extension RangeReplaceableCollection
{
    mutating func resize (_ size: Int, fillWith value: Iterator.Element) -> Void {
        
        let c = self.count
        
        if c < size {
            append(contentsOf: repeatElement(value, count: c.distance(to: size)))
        }
        else if c > size {
            let newEnd = index(startIndex, offsetBy: size)
            removeSubrange(newEnd ..< self.endIndex)
            
        }
    }
}

