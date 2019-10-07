//
//  float4+Extensions.swift
//  LiquidMetal
//
//  Created by Pierre Hanna on 2017-05-16.
//  Copyright © 2017 Pierre Hanna. All rights reserved.
//

import Foundation
import simd


extension simd_float4
{
    func to_float4()->simd_float4
    {
        var mf:simd_float4 = simd_float4()
        
        mf.x = self[0]
        mf.y = self[1]
        mf.z = self[2]
        mf.w = self[3]
        
        return mf
    }

    mutating func normalize()
    {
        self = simd.normalize(self)
    }
    
    func return_normalize() ->simd_float4
    {
        return simd.normalize(self)
    }
    
    //magnitude of a vector
    func norm()->Float
    {
        return simd.norm_inf(self)
    }
    
    func squaredNorm()->Float
    {
        return simd.length_squared(self) //Eigen .squaredNorm()
        
    }
    
    //returns a read-only vector expresssion of the imaginary part (x,y,z)
    mutating func vec()->simd_float3
    {
        return simd_float3(
            self.x,
            self.y,
            self.z
        )
    }    
}
