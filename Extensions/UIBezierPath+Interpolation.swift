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


extension UIBezierPath
{
    func interpolatePointsWithHermite(interpolationPoints : [CGPoint], alpha : CGFloat = 1.0/3.0) {
        
        guard !interpolationPoints.isEmpty else { return }
        self.move(to: interpolationPoints[0])
        
        let n = interpolationPoints.count - 1
        
        for index in 0..<n
        {
            var currentPoint = interpolationPoints[index]
            var nextIndex = (index + 1) % interpolationPoints.count
            var prevIndex = index == 0 ? interpolationPoints.count - 1 : index - 1
            var previousPoint = interpolationPoints[prevIndex]
            var nextPoint = interpolationPoints[nextIndex]
            let endPoint = nextPoint
            var mx : CGFloat
            var my : CGFloat
            
            if index > 0
            {
                mx = (nextPoint.x - previousPoint.x) / 2.0
                my = (nextPoint.y - previousPoint.y) / 2.0
            }
            else
            {
                mx = (nextPoint.x - currentPoint.x) / 2.0
                my = (nextPoint.y - currentPoint.y) / 2.0
            }
            
            let controlPoint1 = CGPoint(x: currentPoint.x + mx * alpha, y: currentPoint.y + my * alpha)
            currentPoint = interpolationPoints[nextIndex]
            nextIndex = (nextIndex + 1) % interpolationPoints.count
            prevIndex = index
            previousPoint = interpolationPoints[prevIndex]
            nextPoint = interpolationPoints[nextIndex]
            
            if index < n - 1
            {
                mx = (nextPoint.x - previousPoint.x) / 2.0
                my = (nextPoint.y - previousPoint.y) / 2.0
            }
            else
            {
                mx = (currentPoint.x - previousPoint.x) / 2.0
                my = (currentPoint.y - previousPoint.y) / 2.0
            }
            
            let controlPoint2 = CGPoint(x: currentPoint.x - mx * alpha, y: currentPoint.y - my * alpha)
            
            self.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        }
    }
}
