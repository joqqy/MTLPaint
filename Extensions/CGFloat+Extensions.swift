//
//  CGFloat+Extensions.swift
//  BigBrush
//
//  Created by Pierre Hanna on 2018-07-19.
//  Copyright © 2018 Pierre Hanna. All rights reserved.
//

import Foundation
import CoreGraphics
import simd

extension CGFloat
{
    public var f:Float  { return Float(self) }
    public var d:Double { return Double(self) }
    public var i:Int    { return Int(self) }
    public var i32:Int32    { return Int32(self) }
    public var ui:UInt  { return UInt(self) }
    public var ui32:UInt32  { return UInt32(self) }
}

extension CGPoint
{
    public var f2: float2  { return float2(Float(self.x), Float(self.y)) }
}

extension CGVector
{
    public var f2:float2  { return float2(Float(self.dx), Float(self.dy)) }
}
