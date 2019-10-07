//
//  matrix_float2x3+Extensions.swift
//  LiquidMetal
//
//  Created by Pierre Hanna on 2017-06-13.
//  Copyright © 2017 Pierre Hanna. All rights reserved.
//

import Foundation
import simd

extension simd_float2x3
{
    func to_float2x3()->simd_float2x3
    {
        var mf:simd_float2x3 = simd_float2x3()
        
        mf[0].x = self.columns.0.x; mf[1].x = self.columns.1.x
        mf[0].y = self.columns.0.y; mf[1].y = self.columns.1.y
        mf[0].z = self.columns.0.z; mf[1].z = self.columns.1.z
        
        return mf
    }
}
