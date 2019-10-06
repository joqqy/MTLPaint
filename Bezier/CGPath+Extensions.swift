//
//  CGPath+Extensions.swift
//  BigBrush
//
//  Created by Pierre Hanna on 2018-09-22.
//  Copyright © 2018 Pierre Hanna. All rights reserved.
//

import Foundation
import UIKit

extension CGPath {
    
//    typealias element = (CGPathElement) -> ()
//    typealias Body = @convention(block) (CGPathElement) -> ()
//    func forEach(body: @escaping Body) -> Void {
//
//        typealias CallBack = @convention(c) (UnsafeMutableRawPointer, UnsafePointer<CGPathElement>) -> ()
//
//        // MARK: I am aware that unsafeBitCast is a dangerous operation unless used with extreme care
//
//        //print(MemoryLayout.size(ofValue: body))
//
//        // argument 1 to .apply
//        // cast closure to unsafePointer
//        let unsafeBodyPtr: UnsafeMutableRawPointer = unsafeBitCast(body, to: UnsafeMutableRawPointer.self)
//
//        // argument 2 to .apply
//        // callback to CGPathApplierFunction - CGPathApplierFunction can view an element in a graphics path
//        let callback: CallBack = { (info, element) in
//            let body:Body = unsafeBitCast(info, to: Body.self)
//            return body(element.pointee)
//        }
//
//        // call .apply
//        // Note, CGPathApplierFunction is typealias to type: (UnsafeMutableRawPointer?, UnsafePointer<CGPathElement>) -> Void
//        let U: CGPathApplierFunction = unsafeBitCast(callback, to: CGPathApplierFunction.self)
//        self.apply(info: unsafeBodyPtr,
//                   function: U)
//    }
    
    // MARK: Avoid using this, use .applyWithBlock instead!
    
   
}

extension CGPath {
   
    // Since Swift 4.1, we can use the applytWithBlock rather than fiddling with c style pointers with apply
    // the apply works, but applyWithBlock should be preferred, it is safer and and easier
    // FIXME: we should implement this computed property for all other correspoinding methods in this extension as well    
    var points: Array<CGPoint>? {
        
        var arrayPoints : Array<CGPoint> = []
        let s: CGFloat = UIScreen.main.scale
        
        self.applyWithBlock { (element: UnsafePointer<CGPathElement>) in
            
            switch (element.pointee.type)
            {
                
            case .moveToPoint, .addLineToPoint:
                arrayPoints.append(element.pointee.points.pointee * s)
                
            case .addQuadCurveToPoint:
                arrayPoints.append(element.pointee.points.pointee * s)
                arrayPoints.append(element.pointee.points.advanced(by: 1).pointee * s)
                
            case .addCurveToPoint:
                arrayPoints.append(element.pointee.points.pointee * s)
                arrayPoints.append(element.pointee.points.advanced(by: 1).pointee * s)
                arrayPoints.append(element.pointee.points.advanced(by: 2).pointee * s)
                
            case .closeSubpath:
                break
                
            default:
                fatalError("unknown error")
            }
        }
        
        return arrayPoints
    }
    

    var points_f2: Array<SIMD2<Float>>? {
        
        get {
            var arrayPoints : Array<SIMD2<Float>> = []
            let s: Float = UIScreen.main.scale.f
            
            self.applyWithBlock { (element: UnsafePointer<CGPathElement>) in
                
                switch (element.pointee.type)
                {
                case .moveToPoint, .addLineToPoint:
                    arrayPoints.append(element.pointee.points.pointee.f2 * s)
                    
                case .addQuadCurveToPoint:
                    arrayPoints.append(element.pointee.points.pointee.f2 * s)
                    arrayPoints.append(element.pointee.points.advanced(by: 1).pointee.f2 * s)
                    
                case .addCurveToPoint:
                    arrayPoints.append(element.pointee.points.pointee.f2 * s)
                    arrayPoints.append(element.pointee.points.advanced(by: 1).pointee.f2 * s)
                    arrayPoints.append(element.pointee.points.advanced(by: 2).pointee.f2 * s)
                    
                case .closeSubpath:
                    break
                    
                default:
                    fatalError("unknown error")
                }
            }
            return arrayPoints
        }
        set(p) {}
    }
    
    var points_f: Array<Float>? {
        
        get {
            var arrayPoints : Array<Float> = []
            let s: Float = UIScreen.main.scale.f
            
            self.applyWithBlock { (element: UnsafePointer<CGPathElement>) in
                
                switch (element.pointee.type)
                {
                case .moveToPoint, .addLineToPoint:
                    arrayPoints.append(element.pointee.points.pointee.f2.x * s)
                    arrayPoints.append(element.pointee.points.pointee.f2.y * s)
                    
                case .addQuadCurveToPoint:
                    arrayPoints.append(element.pointee.points.pointee.f2.x * s)
                    arrayPoints.append(element.pointee.points.pointee.f2.y * s)
                    
                    arrayPoints.append(element.pointee.points.advanced(by: 1).pointee.f2.x * s)
                    arrayPoints.append(element.pointee.points.advanced(by: 1).pointee.f2.y * s)
                    
                case .addCurveToPoint:
                    arrayPoints.append(element.pointee.points.pointee.f2.x * s)
                    arrayPoints.append(element.pointee.points.pointee.f2.y * s)
                    
                    arrayPoints.append(element.pointee.points.advanced(by: 1).pointee.f2.x * s)
                    arrayPoints.append(element.pointee.points.advanced(by: 1).pointee.f2.y * s)
                    
                    arrayPoints.append(element.pointee.points.advanced(by: 2).pointee.f2.x * s)
                    arrayPoints.append(element.pointee.points.advanced(by: 2).pointee.f2.y * s)
                    
                case .closeSubpath:
                    break
                    
                default:
                    fatalError("unknown error")
                }
            }
            return arrayPoints
        }
        set(p) {}
    }
  
}
