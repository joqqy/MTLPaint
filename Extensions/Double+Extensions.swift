//
//  Double+Extensions.swift
//  LiquidMetal
//
//  Created by Pierre Hanna on 2017-06-04.
//  Copyright © 2017 Pierre Hanna. All rights reserved.
//

import Foundation
import CoreGraphics


extension Double
{
    func degrees_2_radians() ->Double
    {
        return self * Double.pi / Double(180)
    }
    
    func radians_2_degrees() ->Double
    {
        return self * Double(180) / Double.pi
    }
    
    public var f:Float  { return Float(self) }
    public var cg:CGFloat { return CGFloat(self) }
    public var i:Int { return Int(self) }
    public var i32:Int32    { return Int32(self) }
    public var ui:UInt  { return UInt(self) }
    public var ui32:UInt32  { return UInt32(self) }
}
