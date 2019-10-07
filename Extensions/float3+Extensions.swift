//
//  float3+Extensions.swift
//  PBD
//
//  Created by Pierre Hanna on 2017-05-11.
//  Copyright © 2017 Pierre Hanna. All rights reserved.
//

import Foundation
import simd
import GLKit


extension simd_float3
{
    func squaredNorm () ->simd_float1
    {
        return length_squared(self)
    }
    
    mutating func setZero()
    {
        self = simd_float3.zero
    }
    
    mutating func normalize()
    {
        self = simd.normalize(self)
    }
    
    func normalize()->simd_float3
    {
        return simd.normalize(self)
    }
    
    func return_normalize()->simd_float3
    {
        return simd.normalize(self)
    }
    
    //magnitude of a vector
    func norm()->Float
    {
        return norm_inf(self)
    }
    
    func to_float3()->simd_float3
    {
        var mf:simd_float3 = simd_float3()
        
        mf[0] = self.x
        mf[1] = self.y
        mf[2] = self.z
        
        return mf
    }

}




