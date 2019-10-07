//
//  Int+Extensions.swift
//  BigBrush
//
//  Created by Pierre Hanna on 2018-08-30.
//  Copyright © 2018 Pierre Hanna. All rights reserved.
//

import Foundation
import CoreGraphics

extension Int
{
    public var f:Float      { return Float(self) }
    public var d:Double     { return Double(self) }
    public var cg:CGFloat   { return CGFloat(self) }
    public var ui:UInt      { return UInt(self) }
    public var i32:Int32    { return Int32(self) }
    public var ui32:UInt32  { return UInt32(self) }
}

extension UInt
{
    
    public var f:Float      { return Float(self) }
    public var d:Double     { return Double(self) }
    public var cg:CGFloat   { return CGFloat(self) }
    public var i32:Int32    { return Int32(self) }
    public var ui:UInt      { return UInt(self) }
    public var ui32:UInt    { return UInt(self) }
    public var i:Int        { return Int(self) }
    public var g: CGFloat   { return CGFloat(self) }
    public var b: Int8      { return Int8(self) }
    public var ub: UInt8    { return UInt8(self) }
    public var s: Int16     { return Int16(self) }
    public var us: UInt16   { return UInt16(self) }
    public var l: Int       { return Int(self) }
    public var ll: Int64    { return Int64(self) }
    public var ull: UInt64  { return UInt64(self) }
}

extension UInt32
{
    
    public var f:Float      { return Float(self) }
    public var d:Double     { return Double(self) }
    public var cg:CGFloat   { return CGFloat(self) }
    public var i32:Int32    { return Int32(self) }
    public var ui:UInt      { return UInt(self) }
    public var i:Int        { return Int(self) }
    
    public var g: CGFloat   { return CGFloat(self) }
    public var b: Int8      { return Int8(self) }
    public var ub: UInt8    { return UInt8(self) }
    public var s: Int16     { return Int16(self) }
    public var us: UInt16   { return UInt16(self) }
    public var l: Int       { return Int(self) }
    public var ul: UInt     { return UInt(self) }
    public var ll: Int64    { return Int64(self) }
    public var ull: UInt64  { return UInt64(self) }
}

extension Int32
{
    
    public var f:Float      { return Float(self) }
    public var d:Double     { return Double(self) }
    public var cg:CGFloat   { return CGFloat(self) }
    public var ui:UInt      { return UInt(self) }
    public var ui32:UInt32  { return UInt32(self) }
    public var i:Int        { return Int(self) }
    public var g: CGFloat   { return CGFloat(self) }
    public var b: Int8      { return Int8(self) }
    public var ub: UInt8    { return UInt8(self) }
    public var s: Int16     { return Int16(self) }
    public var us: UInt16   { return UInt16(self) }
    public var l: Int       { return Int(self) }
    public var ul: UInt     { return UInt(self) }
    public var ll: Int64    { return Int64(self) }
    public var ull: UInt64  { return UInt64(self) }
}

//Darwin clock_types.h
extension UInt64 {
    
    public var g: CGFloat   { return CGFloat(self)}
    public var d: Double    {return Double(self)}
    public var f: Float     {return Float(self)}
    public var b: Int8      {return Int8(self)}
    public var ub: UInt8    {return UInt8(self)}
    public var s: Int16     {return Int16(self)}
    public var us: UInt16   {return UInt16(self)}
    public var i: Int32     {return Int32(self)}
    public var ui: UInt32   {return UInt32(self)}
    public var l: Int       {return Int(self)}
    public var ul: UInt     {return UInt(self)}
    public var ll: Int64    {return Int64(self)}
   
}
