//
//  UIBezierPath+Extensions.swift
//  BigBrush
//
//  Created by Pierre Hanna on 2018-11-12.
//  Copyright © 2018 Pierre Hanna. All rights reserved.
//

import UIKit

extension UIBezierPath {
    
    // reference: https://github.com/erica/iOS-6-Cookbook/blob/master/C01%20Gestures/08%20-%20Smoothed%20Drawing/UIBezierPath-Points.m
    var points: [CGPoint] {
        
        var bezierPoints: [CGPoint] = [CGPoint]()
        
        cgPath.applyWithBlock { (element: UnsafePointer<CGPathElement>) in
            
            if element.pointee.type != .closeSubpath {
                
                bezierPoints.append(element.pointee.points.pointee)
                
                if element.pointee.type != .addLineToPoint && element.pointee.type != .moveToPoint {
                    bezierPoints.append(element.pointee.points.advanced(by: 1).pointee)
                }
            }
            
            if element.pointee.type == .addCurveToPoint {
                bezierPoints.append(element.pointee.points.advanced(by: 2).pointee)
            }
        }
        
        return bezierPoints
    }
    
    func smoothened(granularity: Int) {
        smoothen(granularity: granularity, into: self)
    }
    
    // reference: https://github.com/erica/iOS-6-Cookbook/blob/master/C01%20Gestures/08%20-%20Smoothed%20Drawing/UIBezierPath-Smoothing.m
    @discardableResult
    func smoothen(granularity: Int, into bezier: UIBezierPath? = nil) -> UIBezierPath {
        
        // self.points is a computed property of UIBezierPath
        var allPoints: [CGPoint] = self.points
        
        guard allPoints.count >= 4 else {
            return self
        }
        
        allPoints.insert(allPoints.first!, at: 0)
        allPoints.append(allPoints.last!)
        
        let smoothened: UIBezierPath = bezier ?? (copy() as! UIBezierPath)
        smoothened.removeAllPoints()
        
        for i in (4 ..< allPoints.count) {
            let p0: CGPoint = allPoints[i - 3]
            let p1: CGPoint = allPoints[i - 2]
            let p2: CGPoint = allPoints[i - 1]
            let p3: CGPoint = allPoints[i]
            
            for i in (1 ..< granularity) {
                let t: CGFloat = CGFloat(i) * (CGFloat(1.0) / CGFloat(granularity))
                let tt: CGFloat = t * t
                let ttt: CGFloat = tt * t
                
                func smoothenedCoordinateComponenyFromNearbyPoints(p0: CGFloat, p1: CGFloat, p2: CGFloat, p3: CGFloat) -> CGFloat {
                    // explicit types needed to compile in reasonble time
                    return CGFloat(0.5) *
                        ({ CGFloat(2) * p1 + (p2 - p0) * t }() +
                            { (CGFloat(2) * p0 - CGFloat(5) * p1 + CGFloat(4) * p2 - p3) * tt }() +
                            { (CGFloat(3) * p1 - p0 - CGFloat(3) * p2 + p3) * ttt }())
                }
                
                let pX: CGFloat = smoothenedCoordinateComponenyFromNearbyPoints(p0: p0.x, p1: p1.x, p2: p2.x, p3: p3.x)
                let pY: CGFloat = smoothenedCoordinateComponenyFromNearbyPoints(p0: p0.y, p1: p1.y, p2: p2.y, p3: p3.y)
                smoothened.addLine(to: CGPoint(x: pX, y: pY))
            }
            
            smoothened.addLine(to: p2)
        }
        
        smoothened.addLine(to: allPoints.last!)
        
        return smoothened
    }
}
