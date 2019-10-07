//
//  Float+Extensions.swift
//  LiquidMetal
//
//  Created by Pierre Hanna on 2017-06-04.
//  Copyright © 2017 Pierre Hanna. All rights reserved.
//

import Foundation
import CoreGraphics
import simd

extension simd_float1
{    
    func degrees_2_radians() ->simd_float1
    {
        return self * simd_float1.pi / simd_float1(180)
    }
    
    func radians_2_degrees() ->Float
    {
        return self * simd_float1(180) / simd_float1.pi
    }
    
    public var cg:CGFloat { return CGFloat(self) }
    public var d:Double { return Double(self) }
    public var i:Int { return Int(self) }
    public var i32:Int32    { return Int32(self) }
    public var ui:UInt  { return UInt(self) }
    public var ui32:UInt32  { return UInt32(self) }
}
