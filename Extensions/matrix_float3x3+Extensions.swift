//
//  matrix_float3x3+Extensions.swift
//  LiquidMetal
//
//  Created by Pierre Hanna on 2017-05-14.
//  Copyright © 2017 Pierre Hanna. All rights reserved.
//

import Foundation
import simd


extension simd_float3x3
{
    static prefix func -(_ m0: simd_float3x3) ->simd_float3x3
    {
        let col0 = -m0.columns.0
        let col1 = -m0.columns.1
        let col2 = -m0.columns.2
        
        var m1 = matrix_float3x3()
        m1.columns.0 = col0
        m1.columns.1 = col1
        m1.columns.2 = col2
        
        return m1
    }
    
    mutating func setIdentity()
    {
        self.columns.0 = float3(1, 0, 0)
        self.columns.1 = float3(0, 1, 0)
        self.columns.2 = float3(0, 0, 1)
    }
    
    func return_Identity()->simd_float3x3
    {
        var m0 = simd_float3x3()
        
        m0.columns.0 = float3(1, 0, 0)
        m0.columns.1 = float3(0, 1, 0)
        m0.columns.2 = float3(0, 0, 1)
        
        return m0
    }
    
    
    func to_float3x3()->simd_float3x3
    {
        var mf:simd_float3x3 = simd_float3x3()
        
        mf[0].x = self.columns.0.x; mf[1].x = self.columns.1.x; mf[2].x = self.columns.2.x;
        mf[0].y = self.columns.0.y; mf[1].y = self.columns.1.y; mf[2].y = self.columns.2.y;
        mf[0].z = self.columns.0.z; mf[1].z = self.columns.1.z; mf[2].z = self.columns.2.z;
        
        return mf
    }
    
    func get(_ col: Int, _ row: Int) ->Float
    {
        assert((col < 3 && row < 3) && (col > 0 && row > 0))
        
        if col == 0
        {
            return self.columns.0[row]
        }
        else if col == 1
        {
            return self.columns.1[row]
        }
        else
        {
            return self.columns.2[row]
        }
    }
    
    mutating func set(_ col: Int, _ row: Int, _ val:Float)
    {
        assert((col < 3 && row < 3) && (col > 0 && row > 0))
        
        if col == 0
        {
            self.columns.0[row] = val
        }
        else if col == 1
        {
            self.columns.1[row] = val
        }
        else
        {
            self.columns.2[row] = val
        }
    }
    
    mutating func setZero()
    {
        self = simd_float3x3()
    }
    
    func inverse() ->simd_float3x3
    {
        return self.inverse
    }
    
    func transpose() ->simd_float3x3
    {
        return self.transpose
    }
}
