//
//  UITouch+Extension.swift
//  BigBrush
//
//  Created by Pierre Hanna on 2018-08-01.
//  Copyright © 2018 Pierre Hanna. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

/*
 Overview
 On a 3D Touch device, force from the user's fingers is measured perpendicular to the surface of the screen. However, force reported by Apple Pencil is measured along its long axis, which often is not perpendicular to the screen. Instead of using the Apple Pencil force values as is, you might want to compute only the perpendicular portion of the force so that you can use the same code for touches originating from the user’s fingers or from Apple Pencil.
 Listing 1 shows how to add a perpendicularForce property to the UITouch class to report the perpendicular force supplied by Apple Pencil. For touches involving the stylus, this method divides the reported force value by the sine of the stylus’ altitude. For other touches, it reports the existing force value.
 */
// Getting the perpendicular force from a stylus
extension UITouch {
    
    var perpendicularForce: CGFloat {
        
        get {
            
            if type == .stylus {
                
                return force / sin(self.altitudeAngle)
            }
            else {
                return force
            }
        }
    }
}
