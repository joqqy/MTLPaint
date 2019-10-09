//
//  UIBezierPath+Interpolation.swift
//  BigBrush
//
//  Created by Pierre Hanna on 2018-09-23.
//  Copyright © 2018 Pierre Hanna. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

let kEPSILON:CGFloat = 1.0e-5

class INTERP {
    
    static func interpolateCGPointsWithCatmullRom(
        pointsAsNSValues: [CGPoint],
        closed: Bool,
        alpha: Float) -> UIBezierPath! {
        
            if (pointsAsNSValues.count < 4) {
                return nil
            }
        
            let endIndex:Int = (closed ? pointsAsNSValues.count : pointsAsNSValues.count-2)
            assert( (alpha >= 0.0 && alpha <= 1.0), "alpha value is between 0.0 and 1.0, inclusive")
        
            let path = UIBezierPath()
        
            let startIndex:Int = (closed ? 0 : 1)
            for ii in startIndex ..< endIndex {
         
                var p0:  CGPoint = CGPoint.zero
                var p1:  CGPoint = CGPoint.zero
                var p2:  CGPoint = CGPoint.zero
                var p3:  CGPoint = CGPoint.zero
                
                let nextii: Int      = (ii+1)%pointsAsNSValues.count
                let nextnextii: Int  = (nextii+1)%pointsAsNSValues.count
                let previi: Int      = (ii-1 < 0 ? pointsAsNSValues.count-1 : ii-1)
                
                p1 = pointsAsNSValues[ii]
                p0 = pointsAsNSValues[previi]
                p2 = pointsAsNSValues[nextii]
                p3 = pointsAsNSValues[nextnextii]
                
                let d1: CGFloat = ccpLength(ccpSub(p1, p0))
                let d2: CGFloat = ccpLength(ccpSub(p2, p1))
                let d3: CGFloat = ccpLength(ccpSub(p3, p2))
                
                var b1: CGPoint = CGPoint.zero
                var b2: CGPoint = CGPoint.zero
                
                if (abs(d1) < kEPSILON) {
                    b1 = p1
                } else {
                    b1 = ccpMult(
                        p2,
                        CGFloat(powf(d1.f, 2*alpha))
                    )
                    b1 = ccpSub(
                        b1,
                        ccpMult(
                            p0,
                            CGFloat(powf(d2.f, 2*alpha))
                        )
                    )
                    b1 = ccpAdd(
                        b1,
                        ccpMult(
                            p1,
                            CGFloat((2*powf(d1.f, 2*alpha) + 3*powf(d1.f, alpha)*powf(d2.f, alpha) + powf(d2.f, 2*alpha)))
                        )
                    )
                    b1 = ccpMult(
                        b1,
                        CGFloat(1.0/(3*powf(d1.f, alpha)*(powf(d1.f, alpha) + powf(d2.f, alpha)))) )
                }
                
                if (abs(d3) < kEPSILON) {
                    b2 = p2
                } else {
                    b2 = ccpMult(
                        p1,
                        CGFloat(powf(d3.f, 2*alpha))
                    )
                    b2 = ccpSub(
                        b2,
                        ccpMult(
                            p3,
                            CGFloat(powf(d2.f, 2*alpha))
                        )
                    )
                    b2 = ccpAdd(
                        b2, ccpMult(
                            p2,
                            CGFloat((2*powf(d3.f, 2*alpha) + 3*powf(d3.f, alpha)*powf(d2.f, alpha) + powf(d2.f, 2*alpha)))
                        )
                    )
                    b2 = ccpMult(
                        b2,
                        CGFloat(1.0 / (3*powf(d3.f, alpha)*(powf(d3.f, alpha)+powf(d2.f, alpha))))
                    )
                }
                
                if (ii == startIndex) {
                    path.move(to: p1)
                }
                
                path.addCurve(
                    to: p2,
                    controlPoint1: b1,
                    controlPoint2: b2)
            }
        
            if (closed) {
                path.close()
            }
            return path
    }
    
    
    static func interpolateCGPointsWithHermite(
        pointsAsNSValues: [CGPoint],
        closed:Bool) -> UIBezierPath! {
        
        if pointsAsNSValues.count < 2 {
            return nil
        }
        
        let nCurves:Int = (closed) ? pointsAsNSValues.count : pointsAsNSValues.count-1
        let path:UIBezierPath = UIBezierPath()
        
        for ii in 0 ..< nCurves {
            
            var curPt:  CGPoint = CGPoint.zero
            var prevPt: CGPoint = CGPoint.zero
            var nextPt: CGPoint = CGPoint.zero
            var endPt:  CGPoint = CGPoint.zero
            
            var mx:CGFloat
            var my:CGFloat
            
            //---------------------------------------------------
            curPt = pointsAsNSValues[ii]
            if (ii == 0) {
                path.move(to: curPt)
            }
            var nextii:Int = (ii+1)%pointsAsNSValues.count
            var previi:Int = (ii-1 < 0 ? pointsAsNSValues.count-1 : ii-1)
            prevPt = pointsAsNSValues[previi]
            nextPt = pointsAsNSValues[nextii]
            endPt = nextPt
            if (closed || ii > 0) {
                mx = (nextPt.x - curPt.x)*0.5 + (curPt.x - prevPt.x)*0.5
                my = (nextPt.y - curPt.y)*0.5 + (curPt.y - prevPt.y)*0.5
            } else {
                mx = (nextPt.x - curPt.x)*0.5
                my = (nextPt.y - curPt.y)*0.5
            }
            // control point 1
            var ctrlPt1:CGPoint = CGPoint.zero
            ctrlPt1.x = curPt.x + mx / 3.0
            ctrlPt1.y = curPt.y + my / 3.0
            
            //---------------------------------------------------
            curPt = pointsAsNSValues[nextii]
            nextii = (nextii+1) % pointsAsNSValues.count
            previi = ii
            prevPt = pointsAsNSValues[previi]
            nextPt = pointsAsNSValues[nextii]
            if (closed || ii < nCurves-1) {
                mx = (nextPt.x - curPt.x)*0.5 + (curPt.x - prevPt.x)*0.5
                my = (nextPt.y - curPt.y)*0.5 + (curPt.y - prevPt.y)*0.5
            } else {
                mx = (curPt.x - prevPt.x)*0.5
                my = (curPt.y - prevPt.y)*0.5
            }
            // control point 2
            var ctrlPt2:CGPoint = CGPoint.zero
            ctrlPt2.x = curPt.x - mx / 3.0
            ctrlPt2.y = curPt.y - my / 3.0
            
            //---------------------------------------------------
            path.addCurve(
                to: endPt,
                controlPoint1: ctrlPt1,
                controlPoint2: ctrlPt2)
        }
        
        if (closed) {
            path.close()
        }
        
        return path
    }
}



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
        
        let smoothened: UIBezierPath = UIBezierPath() // bezier ?? (copy() as! UIBezierPath)
        //smoothened.removeAllPoints()
        
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
