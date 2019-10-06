//
//  float2x3+Extensions.swift
//  LiquidMetal
//
//  Created by Pierre Hanna on 2017-06-13.
//  Copyright © 2017 Pierre Hanna. All rights reserved.
//

import Foundation
import simd


extension float2x3
{
    func to_matrix_float2x3()->matrix_float2x3
    {
        var mf:matrix_float2x3 = matrix_float2x3()
        
        mf.columns.0.x = self[0][0]; mf.columns.1.x = self[1][0]
        mf.columns.0.y = self[0][1]; mf.columns.1.y = self[1][1]
        mf.columns.0.z = self[0][2]; mf.columns.1.z = self[1][2]
        
        return mf
    }
}
