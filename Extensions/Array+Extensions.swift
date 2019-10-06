//
//  Array+Extensions.swift
//  LiquidMetal
//
//  Created by Pierre Hanna on 2017-05-27.
//  Copyright © 2017 Pierre Hanna. All rights reserved.
//

import Foundation


extension RangeReplaceableCollection
{
    public mutating func resize (
        _ size:         IndexDistance,
        fillWith value: Iterator.Element
        )
    {
        let c = self.count
        
        if c < size
        {
            append(contentsOf: repeatElement(value, count: c.distance(to: size)))
        }
        else if c > size
        {
            let newEnd = index(startIndex, offsetBy: size)
            removeSubrange(newEnd ..< self.endIndex)
            
        }
    }
}
