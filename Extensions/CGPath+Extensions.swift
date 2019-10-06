//
//  CGPath+Extensions.swift
//  BigBrush
//
//  Created by Pierre Hanna on 2018-09-22.
//  Copyright © 2018 Pierre Hanna. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

extension CGPath {
    
    func forEach( body: @escaping @convention(block) (CGPathElement) -> Void) {
        
        typealias Body = @convention(block) (CGPathElement) -> Void
        let callback: @convention(c) (UnsafeMutableRawPointer, UnsafePointer<CGPathElement>) -> Void = { (info, element) in
            let body = unsafeBitCast(info, to: Body.self)
            body(element.pointee)
        }
        //print(MemoryLayout.size(ofValue: body))
        let unsafeBody = unsafeBitCast(body, to: UnsafeMutableRawPointer.self)
        self.apply(info: unsafeBody, function: unsafeBitCast(callback, to: CGPathApplierFunction.self))
    }
    
    func getPathElementsPoints() -> [CGPoint] {
        var arrayPoints : [CGPoint]! = [CGPoint]()
        self.forEach { element in
            switch (element.type) {
            case CGPathElementType.moveToPoint:
                arrayPoints.append(element.points[0])
            case .addLineToPoint:
                arrayPoints.append(element.points[0])
            case .addQuadCurveToPoint:
                arrayPoints.append(element.points[0])
                arrayPoints.append(element.points[1])
            case .addCurveToPoint:
                arrayPoints.append(element.points[0])
                arrayPoints.append(element.points[1])
                arrayPoints.append(element.points[2])
            default: break
            }
        }
        return arrayPoints
    }
    
    func getPathElementsPointsAndTypes() -> ([CGPoint],[CGPathElementType]) {
        var arrayPoints : [CGPoint]! = [CGPoint]()
        var arrayTypes : [CGPathElementType]! = [CGPathElementType]()
        self.forEach { element in
            switch (element.type) {
            case CGPathElementType.moveToPoint:
                arrayPoints.append(element.points[0])
                arrayTypes.append(element.type)
            case .addLineToPoint:
                arrayPoints.append(element.points[0])
                arrayTypes.append(element.type)
            case .addQuadCurveToPoint:
                arrayPoints.append(element.points[0])
                arrayPoints.append(element.points[1])
                arrayTypes.append(element.type)
                arrayTypes.append(element.type)
            case .addCurveToPoint:
                arrayPoints.append(element.points[0])
                arrayPoints.append(element.points[1])
                arrayPoints.append(element.points[2])
                arrayTypes.append(element.type)
                arrayTypes.append(element.type)
                arrayTypes.append(element.type)
            default: break
            }
        }
        return (arrayPoints,arrayTypes)
    }
    
    
    
//
//    // Since Swift 4.1, we can use the applytWithBlock rather than fiddling with c style pointers with apply
//    // the apply works, but applyWithBlock should be preferred, it is safer and and easier
//    // FIXME: we should implement this computed property for all other correspoinding methods in this extension as well
//    var points: Array<CGPoint>? {
//        
//        var arrayPoints : Array<CGPoint> = []
//        let s: CGFloat = UIScreen.main.scale
//
//        self.applyWithBlock { (element: UnsafePointer<CGPathElement>) in
//
//            switch (element.pointee.type)
//            {
//
//            case .moveToPoint, .addLineToPoint:
//                arrayPoints.append(element.pointee.points.pointee * s)
//
//            case .addQuadCurveToPoint:
//                arrayPoints.append(element.pointee.points.pointee * s)
//                arrayPoints.append(element.pointee.points.advanced(by: 1).pointee * s)
//
//            case .addCurveToPoint:
//                arrayPoints.append(element.pointee.points.pointee * s)
//                arrayPoints.append(element.pointee.points.advanced(by: 1).pointee * s)
//                arrayPoints.append(element.pointee.points.advanced(by: 2).pointee * s)
//
//            case .closeSubpath:
//                break
//
//            default:
//                fatalError("unknown error")
//            }
//        }
//
//        return arrayPoints
//    }
    

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
