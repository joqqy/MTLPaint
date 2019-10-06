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

let kEPSILON: CGFloat = 1.0e-5

class INTERP {
    
//    static func interpolateCGPointsWithCatmullRom(pointsAsNSValues: [CGPoint], closed: Bool, alpha: Float) -> UIBezierPath! {
//
//        if (pointsAsNSValues.count < 4) {
//            return nil
//        }
//
//        let endIndex: Int = (closed ? pointsAsNSValues.count : pointsAsNSValues.count - 2)
//        assert( (alpha >= 0.0 && alpha <= 1.0), "alpha value is between 0.0 and 1.0, inclusive")
//
//        let path: UIBezierPath = UIBezierPath()
//        let startIndex: Int = (closed ? 0 : 1)
//        for ii in startIndex ..< endIndex {
//
//            var p0: CGPoint = CGPoint.zero
//            var p1: CGPoint = CGPoint.zero
//            var p2: CGPoint = CGPoint.zero
//            var p3: CGPoint = CGPoint.zero
//
//            let nextii: Int = (ii+1)%pointsAsNSValues.count
//            let nextnextii: Int = (nextii+1)%pointsAsNSValues.count
//            let previi: Int = (ii-1 < 0 ? pointsAsNSValues.count-1 : ii - 1)
//
//            p1 = pointsAsNSValues[ii]
//            p0 = pointsAsNSValues[previi]
//            p2 = pointsAsNSValues[nextii]
//            p3 = pointsAsNSValues[nextnextii]
//
//            let d1: CGFloat = ccpLength(ccpSub(p1, p0))
//            let d2: CGFloat = ccpLength(ccpSub(p2, p1))
//            let d3: CGFloat = ccpLength(ccpSub(p3, p2))
//
//            var b1: CGPoint = CGPoint.zero
//            var b2: CGPoint = CGPoint.zero
//
//            if (abs(d1) < kEPSILON) {
//                b1 = p1
//
//            } else {
//                b1 = ccpMult(p2, CGFloat(powf(d1.f, 2 * alpha)))
//                b1 = ccpSub(b1, ccpMult(p0, CGFloat(powf(d2.f, 2 * alpha))))
//                b1 = ccpAdd(b1, ccpMult(p1, CGFloat((2 * powf(d1.f, 2 * alpha) + 3 * powf(d1.f, alpha) * powf(d2.f, alpha) + powf(d2.f, 2 * alpha)))))
//                b1 = ccpMult(b1, CGFloat(1.0/(3 * powf(d1.f, alpha) * (powf(d1.f, alpha) + powf(d2.f, alpha)))))
//            }
//
//            if (abs(d3) < kEPSILON) {
//                b2 = p2
//
//            } else {
//                b2 = ccpMult(p1, CGFloat(powf(d3.f, 2 * alpha)))
//                b2 = ccpSub(b2, ccpMult(p3, CGFloat(powf(d2.f, 2 * alpha))))
//                b2 = ccpAdd(b2, ccpMult(p2, CGFloat((2 * powf(d3.f, 2 * alpha) + 3 * powf(d3.f, alpha) * powf(d2.f, alpha) + powf(d2.f, 2 * alpha)))))
//                b2 = ccpMult(b2, CGFloat(1.0 / (3 * powf(d3.f, alpha) * (powf(d3.f, alpha) + powf(d2.f, alpha)))))
//            }
//
//            if (ii == startIndex) {
//                path.move(to: p1)
//            }
//
//            path.addCurve(
//                to: p2,
//                controlPoint1: b1,
//                controlPoint2: b2)
//        }
//
//        if (closed) {
//            path.close()
//        }
//        return path
//    }
    
    
    static func interpolateCGPointsWithHermite(pointsAsNSValues: [CGPoint], closed: Bool) -> UIBezierPath! {
        
            if pointsAsNSValues.count < 2 {
                return nil
            }
        
            let nCurves: Int = (closed) ? pointsAsNSValues.count : pointsAsNSValues.count-1
            let path: UIBezierPath = UIBezierPath()
        
            for ii in 0 ..< nCurves {
                
                var curPt: CGPoint = CGPoint.zero
                var prevPt: CGPoint = CGPoint.zero
                var nextPt: CGPoint = CGPoint.zero
                var endPt: CGPoint = CGPoint.zero
                
                var mx: CGFloat
                var my: CGFloat
                
                //---------------------------------------------------
                curPt = pointsAsNSValues[ii]
                if (ii == 0) {
                    path.move(to: curPt)
                }
                var nextii: Int = (ii+1) % pointsAsNSValues.count
                var previi: Int = (ii-1 < 0 ? pointsAsNSValues.count-1 : ii-1)
                prevPt = pointsAsNSValues[previi]
                nextPt = pointsAsNSValues[nextii]
                endPt = nextPt
                if (closed || ii > 0) {
                    mx = ((nextPt.x - curPt.x) * 0.5) + ((curPt.x - prevPt.x) * 0.5)
                    my = ((nextPt.y - curPt.y) * 0.5) + ((curPt.y - prevPt.y) * 0.5)
                    
                } else {
                    mx = (nextPt.x - curPt.x) * 0.5
                    my = (nextPt.y - curPt.y) * 0.5
                }
                // control point 1
                var ctrlPt1: CGPoint = CGPoint.zero
                ctrlPt1.x = curPt.x + mx / 3.0
                ctrlPt1.y = curPt.y + my / 3.0                
                
                //---------------------------------------------------
                curPt = pointsAsNSValues[nextii]
                nextii = (nextii+1) % pointsAsNSValues.count
                previi = ii
                prevPt = pointsAsNSValues[previi]
                nextPt = pointsAsNSValues[nextii]
                if (closed || ii < nCurves-1) {
                    mx = ((nextPt.x - curPt.x) * 0.5) + ((curPt.x - prevPt.x) * 0.5)
                    my = ((nextPt.y - curPt.y) * 0.5) + ((curPt.y - prevPt.y) * 0.5)
                    
                } else {
                    mx = (curPt.x - prevPt.x) * 0.5
                    my = (curPt.y - prevPt.y) * 0.5
                }
                // control point 2
                var ctrlPt2:CGPoint = CGPoint.zero
                ctrlPt2.x = curPt.x - (mx / 3.0)
                ctrlPt2.y = curPt.y - (my / 3.0)
                
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
    static func interpolateCGPointsWithHermite_v2(pointsAsNSValues : [CGPoint], closed: Bool) -> UIBezierPath! {
        if pointsAsNSValues.count < 2 {
            return nil
        }
        
        let n: Int = pointsAsNSValues.count - 1
        let path: UIBezierPath = UIBezierPath()
        
        for ii in 0 ..< n {
            var currentPoint: CGPoint = pointsAsNSValues[ii]
            
            if ii == 0 {
                path.move(to: pointsAsNSValues[0])
            }
            
            var nextii: Int = (ii + 1) % pointsAsNSValues.count
            var previi: Int = (ii - 1 < 0 ? pointsAsNSValues.count - 1 : ii - 1);
            var previousPoint: CGPoint = pointsAsNSValues[previi]
            var nextPoint: CGPoint = pointsAsNSValues[nextii]
            let endPoint: CGPoint = nextPoint;
            var mx: CGFloat = 0.0
            var my: CGFloat = 0.0
            
            if ii > 0 {
                mx = ((nextPoint.x - currentPoint.x) * 0.5) + ((currentPoint.x - previousPoint.x) * 0.5)
                my = ((nextPoint.y - currentPoint.y) * 0.5) + ((currentPoint.y - previousPoint.y) * 0.5)
                
            } else {
                mx = (nextPoint.x - currentPoint.x) * 0.5
                my = (nextPoint.y - currentPoint.y) * 0.5
            }
            
            let controlPoint1: CGPoint = CGPoint(x: currentPoint.x + (mx / 3.0), y: currentPoint.y + (my / 3.0))
            
            currentPoint = pointsAsNSValues[nextii]
            nextii = (nextii + 1) % pointsAsNSValues.count
            previi = ii;
            previousPoint = pointsAsNSValues[previi]
            nextPoint = pointsAsNSValues[nextii]
            
            if ii < n - 1 {
                mx = ((nextPoint.x - currentPoint.x) * 0.5) + ((currentPoint.x - previousPoint.x) * 0.5)
                my = ((nextPoint.y - currentPoint.y) * 0.5) + ((currentPoint.y - previousPoint.y) * 0.5)
            } else {
                mx = (currentPoint.x - previousPoint.x) * 0.5
                my = (currentPoint.y - previousPoint.y) * 0.5
            }
            
            let controlPoint2: CGPoint = CGPoint(x: currentPoint.x - (mx / 3.0), y: currentPoint.y - (my / 3.0))
            
            path.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        }
        
        if (closed) {
            path.close()
        }
        
        return path
    }
}

extension UIBezierPath
{
//    func interpolateCGPointsWithCatmullRom(pointsAsNSValues: [CGPoint], closed: Bool, alpha: Float) -> Void {
//        
//        guard (pointsAsNSValues.count < 4) else {
//            return
//        }
//        
//        let endIndex: Int = (closed ? pointsAsNSValues.count : pointsAsNSValues.count - 2)
//        assert( (alpha >= 0.0 && alpha <= 1.0), "alpha value is between 0.0 and 1.0, inclusive")
//
//        let startIndex: Int = (closed ? 0 : 1)
//        for ii in startIndex ..< endIndex {
//            
//            var p0: CGPoint = CGPoint.zero
//            var p1: CGPoint = CGPoint.zero
//            var p2: CGPoint = CGPoint.zero
//            var p3: CGPoint = CGPoint.zero
//            
//            let nextii: Int = (ii + 1) % pointsAsNSValues.count
//            let nextnextii: Int = (nextii+1) % pointsAsNSValues.count
//            let previi: Int = ((ii - 1) < 0 ? pointsAsNSValues.count-1 : ii - 1)
//            
//            p1 = pointsAsNSValues[ii]
//            p0 = pointsAsNSValues[previi]
//            p2 = pointsAsNSValues[nextii]
//            p3 = pointsAsNSValues[nextnextii]
//            
//            let d1: CGFloat = ccpLength(ccpSub(p1, p0))
//            let d2: CGFloat = ccpLength(ccpSub(p2, p1))
//            let d3: CGFloat = ccpLength(ccpSub(p3, p2))
//            
//            var b1: CGPoint = CGPoint.zero
//            var b2: CGPoint = CGPoint.zero
//            
//            if (abs(d1) < kEPSILON) {
//                b1 = p1
//            } else {
//                b1 = ccpMult(p2, CGFloat(powf(d1.f, 2*alpha)))
//                b1 = ccpSub(b1, ccpMult(p0, CGFloat(powf(d2.f, 2*alpha))))
//                b1 = ccpAdd(b1, ccpMult(p1, CGFloat((2*powf(d1.f, 2*alpha) + 3*powf(d1.f, alpha)*powf(d2.f, alpha) + powf(d2.f, 2*alpha)))))
//                b1 = ccpMult(b1, CGFloat(1.0/(3*powf(d1.f, alpha)*(powf(d1.f, alpha) + powf(d2.f, alpha)))))
//            }
//            
//            if (abs(d3) < kEPSILON) {
//                b2 = p2
//            } else {
//                b2 = ccpMult(p1, CGFloat(powf(d3.f, 2*alpha)))
//                b2 = ccpSub(b2, ccpMult(p3, CGFloat(powf(d2.f, 2*alpha))))
//                b2 = ccpAdd(b2, ccpMult(p2, CGFloat((2*powf(d3.f, 2*alpha) + 3*powf(d3.f, alpha)*powf(d2.f, alpha) + powf(d2.f, 2*alpha)))))
//                b2 = ccpMult(b2, CGFloat(1.0 / (3*powf(d3.f, alpha)*(powf(d3.f, alpha)+powf(d2.f, alpha)))))
//            }
//            
//            if (ii == startIndex) {
//                self.move(to: p1)
//            }
//            
//            self.addCurve(
//                to: p2,
//                controlPoint1: b1,
//                controlPoint2: b2)
//        }
//        
//        if (closed) {
//            self.close()
//        }
//    }
    
    func interpolateCGPointsWithHermite(pointsAsNSValues: [CGPoint], closed: Bool) -> Void {
        
        guard (pointsAsNSValues.count < 2) else {
            return
        }
        
        let nCurves: Int = (closed) ? pointsAsNSValues.count : pointsAsNSValues.count-1
        
        for ii in 0 ..< nCurves {
            
            var curPt: CGPoint = CGPoint.zero
            var prevPt: CGPoint = CGPoint.zero
            var nextPt: CGPoint = CGPoint.zero
            var endPt: CGPoint = CGPoint.zero
            
            var mx: CGFloat
            var my: CGFloat
            
            curPt = pointsAsNSValues[ii]
            if (ii == 0) {
                self.move(to: curPt)
            }
            var nextii: Int = (ii+1)%pointsAsNSValues.count
            var previi: Int = (ii-1 < 0 ? pointsAsNSValues.count-1 : ii-1)
            prevPt = pointsAsNSValues[previi]
            nextPt = pointsAsNSValues[nextii]
            endPt = nextPt
            if (closed || ii > 0) {
                mx = ((nextPt.x - curPt.x) * 0.5) + ((curPt.x - prevPt.x) * 0.5)
                my = ((nextPt.y - curPt.y) * 0.5) + ((curPt.y - prevPt.y) * 0.5)
                
            } else {
                mx = (nextPt.x - curPt.x) * 0.5
                my = (nextPt.y - curPt.y) * 0.5
            }
            // control point 1
            var ctrlPt1: CGPoint = CGPoint.zero
            ctrlPt1.x = curPt.x + (mx / 3.0)
            ctrlPt1.y = curPt.y + (my / 3.0)
            
            curPt = pointsAsNSValues[nextii]
            nextii = (nextii+1) % pointsAsNSValues.count
            previi = ii
            prevPt = pointsAsNSValues[previi]
            nextPt = pointsAsNSValues[nextii]
            if (closed || ii < nCurves-1) {
                mx = ((nextPt.x - curPt.x) * 0.5) + ((curPt.x - prevPt.x) * 0.5)
                my = ((nextPt.y - curPt.y) * 0.5) + ((curPt.y - prevPt.y) * 0.5)
                
            } else {
                mx = (curPt.x - prevPt.x) * 0.5
                my = (curPt.y - prevPt.y) * 0.5
            }
            // control point 2
            var ctrlPt2: CGPoint = CGPoint.zero
            ctrlPt2.x = curPt.x - (mx / 3.0)
            ctrlPt2.y = curPt.y - (my / 3.0)
            
            self.addCurve(
                to: endPt,
                controlPoint1: ctrlPt1,
                controlPoint2: ctrlPt2)
        }
        
        if (closed) {
            self.close()
        }
    }
    
    func interpolateCGPointsWithHermite_v2(interpolationPoints : [CGPoint], closed: Bool) -> Void {
        
        let n: Int = interpolationPoints.count - 1
        
        for ii in 0 ..< n {
            
            var currentPoint: CGPoint = interpolationPoints[ii]
            
            if ii == 0 {
                self.move(to: interpolationPoints[0])
            }
            
            var nextii = (ii + 1) % interpolationPoints.count
            var previi = (ii - 1 < 0 ? interpolationPoints.count - 1 : ii-1);
            var previousPoint: CGPoint = interpolationPoints[previi]
            var nextPoint: CGPoint = interpolationPoints[nextii]
            let endPoint: CGPoint = nextPoint;
            var mx: CGFloat = 0.0
            var my: CGFloat = 0.0
            
            if ii > 0 {
                mx = ((nextPoint.x - currentPoint.x) * 0.5) + ((currentPoint.x - previousPoint.x) * 0.5)
                my = ((nextPoint.y - currentPoint.y) * 0.5) + ((currentPoint.y - previousPoint.y) * 0.5)
                
            } else {
                mx = (nextPoint.x - currentPoint.x) * 0.5
                my = (nextPoint.y - currentPoint.y) * 0.5
            }
            
            let controlPoint1: CGPoint = CGPoint(x: currentPoint.x + (mx / 3.0), y: currentPoint.y + (my / 3.0))
            
            currentPoint = interpolationPoints[nextii]
            nextii = (nextii + 1) % interpolationPoints.count
            previi = ii;
            previousPoint = interpolationPoints[previi]
            nextPoint = interpolationPoints[nextii]
            
            if ii < n - 1 {
                mx = ((nextPoint.x - currentPoint.x) * 0.5) + ((currentPoint.x - previousPoint.x) * 0.5)
                my = ((nextPoint.y - currentPoint.y) * 0.5) + ((currentPoint.y - previousPoint.y) * 0.5)
                
            } else {
                mx = (currentPoint.x - previousPoint.x) * 0.5
                my = (currentPoint.y - previousPoint.y) * 0.5
            }
            
            let controlPoint2: CGPoint = CGPoint(x: currentPoint.x - (mx / 3.0), y: currentPoint.y - (my / 3.0))
            
            self.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        }
        
        if (closed) {
            self.close()
        }
    }
}


extension CGFloat
{
    func toFloat() -> Float {
        return Float(self)
    }
}

extension CIVector
{
    func toArray() -> [CGFloat] {
        var returnArray: [CGFloat] = [CGFloat]()
        
        for i in 0 ..< self.count {
            returnArray.append(self.value(at: i))
        }
        
        return returnArray
    }
    
    func normalize() -> CIVector {
        var sum: CGFloat = 0
        
        for i in 0 ..< self.count {
            sum += self.value(at: i)
        }
        
        if sum == 0 {
            return self
        }
        
        var normalizedValues: [CGFloat] = [CGFloat]()
        
        for i in 0 ..< self.count {
            normalizedValues.append(self.value(at: i) / sum)
        }
        
        return CIVector(values: normalizedValues,
                        count: normalizedValues.count)
    }
    
    func multiply(_ value: CGFloat) -> CIVector {
        
        let n: Int = self.count
        var targetArray: [CGFloat] = [CGFloat]()
        
        for i in 0 ..< n {
            targetArray.append(self.value(at: i) * value)
        }
        
        return CIVector(values: targetArray, count: n)
    }
    
    func interpolateTo(_ target: CIVector, value: CGFloat) -> CIVector {
        
        return CIVector(
            x: self.x + ((target.x - self.x) * value),
            y: self.y + ((target.y - self.y) * value))
    }
}


extension UIColor
{
    func hue() -> CGFloat {
        
        var hue: CGFloat = 0.0
        var saturation: CGFloat = 0.0
        var brightness: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        
        self.getHue(&hue,
                    saturation: &saturation,
                    brightness: &brightness,
                    alpha: &alpha)
        
        return hue
    }
}

/// A Swiftified representation of a `CGPathElement`
/// Simpler and safer than `CGPathElement`.
public enum PathElement {
    
    case moveToPoint(CGPoint)
    case addLineToPoint(CGPoint)
    case addQuadCurveToPoint(CGPoint, CGPoint)
    case addCurveToPoint(CGPoint, CGPoint, CGPoint)
    case closeSubpath
    
    init(element: CGPathElement) {
        
        switch element.type
        {
        case .moveToPoint:
            self = .moveToPoint(element.points[0])
            
        case .addLineToPoint:
            self = .addLineToPoint(element.points[0])
            
        case .addQuadCurveToPoint:
            self = .addQuadCurveToPoint(element.points[0],
                                        element.points[1])
        case .addCurveToPoint:
            self = .addCurveToPoint(element.points[0],
                                    element.points[1],
                                    element.points[2])
        case .closeSubpath:
            self = .closeSubpath
            
        @unknown default:
            fatalError("New unhandled case - Switch needs an update to handle all cases")
        }
    }
}

extension PathElement: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        
        switch self
        {
        case let .moveToPoint(point):
            return "moveto \(point)"
            
        case let .addLineToPoint(point):
            return "lineto \(point)"
            
        case let .addQuadCurveToPoint(point1, point2):
            return "quadcurveto \(point1), \(point2)"
            
        case let .addCurveToPoint(point1, point2, point3):
            return "curveto \(point1), \(point2), \(point3)"
            
        case .closeSubpath:
            return "closepath"
        }
    }
}

extension PathElement: Equatable {
    
    public static func ==(lhs: PathElement, rhs: PathElement) -> Bool {
        
        switch(lhs, rhs)
        {
        case let (.moveToPoint(l), .moveToPoint(r)):
            return l == r
            
        case let (.addLineToPoint(l), .addLineToPoint(r)):
            return l == r
            
        case let (.addQuadCurveToPoint(l1, l2), .addQuadCurveToPoint(r1, r2)):
            return l1 == r1 && l2 == r2
            
        case let (.addCurveToPoint(l1, l2, l3), .addCurveToPoint(r1, r2, r3)):
            return l1 == r1 && l2 == r2 && l3 == r3
            
        case (.closeSubpath, .closeSubpath):
            return true
            
        case (_, _):
            return false
        }
    }
}

class Box<T> {
    
    private(set) var unbox: T
    
    init(_ value: T) {
        self.unbox = value
    }
    
    /// Use this method to mutate the boxed value.
    func mutate(_ mutation: (inout T) -> ()) {
        mutation(&unbox)
    }
}

extension UIBezierPath {
    
    var elements: [PathElement] {
        
        var pathElements: [PathElement] = []
        
        // Wrap the array in a Box
        // Wrap the box in an Unmanaged
        let unmanaged = Unmanaged.passRetained(Box(pathElements))
        self.cgPath.apply(info: unmanaged.toOpaque()) {
            
            userInfo, nextElementPointer in
            
            // Create the new path element
            let nextElement = PathElement(
                element: nextElementPointer.pointee)
            
            // Unbox the array and append
            let box: Box<[PathElement]> =
                Unmanaged.fromOpaque(userInfo!).takeUnretainedValue()
            
            box.mutate { array in array.append(nextElement) }
        }
        // Unwrap the array
        pathElements = unmanaged.takeRetainedValue().unbox
        return pathElements
    }
}

extension UIBezierPath: Sequence {
    public func makeIterator() -> AnyIterator<PathElement> {
        return AnyIterator(elements.makeIterator())
    }
}
