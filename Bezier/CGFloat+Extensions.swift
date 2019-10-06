//
//  CGFloat+Extensions.swift
//  BigBrush
//
//  Created by Pierre Hanna on 2018-07-19.
//  Copyright © 2018 Pierre Hanna. All rights reserved.
//

import Foundation
import UIKit

// MARK: operator overload for multiplying a CGPoint * CGFloat


extension CGFloat
{
    
    var f: Float { return Float(self) }
    var i: Int { return Int(self) }
    var i32: Int32 { return Int32(self) }
    var ui: UInt { return UInt(self) }
    var ui32: UInt32 { return UInt32(self) }
}

extension CGPoint
{
    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        
        let x: CGFloat = lhs.x * rhs
        let y: CGFloat = lhs.y * rhs
        
        return CGPoint(x: x, y: y)
    }
    
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        
        let x: CGFloat = lhs.x + rhs.x
        let y: CGFloat = lhs.y + rhs.y
        
        return CGPoint(x: x, y: y)
    }
    
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        
        let x: CGFloat = lhs.x - rhs.x
        let y: CGFloat = lhs.y - rhs.y
        
        return CGPoint(x: x, y: y)
    }
    
    var i2: SIMD2<Int32> { return SIMD2<Int32>(Int32(self.x), Int32(self.y)) }
    var f2: SIMD2<Float> { return SIMD2<Float>(Float(self.x), Float(self.y)) }
    var f3: SIMD3<Float> { return SIMD3<Float>(Float(self.x), Float(self.y), 0) }
    var f4: SIMD4<Float> { return SIMD4<Float>(Float(self.x), Float(self.y), 0, 0) }
    var f4_1: SIMD4<Float> { return SIMD4<Float>(Float(self.x), Float(self.y), 0, 1) }
    var d2: SIMD2<Double> { return SIMD2<Double>(Double(self.x), Double(self.y)) }
    
}

extension CGVector
{
    var i2: SIMD2<Int32> { return SIMD2<Int32>(Int32(self.dx), Int32(self.dy)) }
    var f2: SIMD2<Float> { return SIMD2<Float>(Float(self.dx), Float(self.dy)) }
    var d2: SIMD2<Double> { return SIMD2<Double>(Double(self.dx), Double(self.dy)) }
}
