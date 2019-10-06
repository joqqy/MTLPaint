//
//  float3x3+Extensions.swift
//  PBD
//
//  Created by Pierre Hanna on 2017-05-11.
//  Copyright © 2017 Pierre Hanna. All rights reserved.
//

import Foundation
import simd
import GLKit


extension simd_float3x3
{
    mutating func setIdentity() ->simd_float3x3
    {
        self[0].x = 1.0; self[0].y = 0.0; self[0].z = 0.0
        self[1].x = 0.0; self[1].y = 1.0; self[1].z = 0.0
        self[2].x = 0.0; self[2].y = 0.0; self[2].z = 1.0
        return self
    }
    
    mutating func setZero() ->simd_float3x3
    {
        self[0].x = 0.0; self[0].y = 0.0; self[0].z = 0.0
        self[1].x = 0.0; self[1].y = 0.0; self[1].z = 0.0
        self[2].x = 0.0; self[2].y = 0.0; self[2].z = 0.0
        return self
    }
    
    func to_matrix_float3x3()->simd_float3x3
    {
        var mf:simd_float3x3 = simd_float3x3()
        
        mf.columns.0.x = self[0].x; mf.columns.1.x = self[1].x; mf.columns.2.x = self[2].x
        mf.columns.0.y = self[0].y; mf.columns.1.y = self[1].y; mf.columns.2.y = self[2].y
        mf.columns.0.z = self[0].z; mf.columns.1.z = self[1].z; mf.columns.2.z = self[2].z
        
        return mf
    }
}
