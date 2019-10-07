//
//  extra_matrix_utilities.swift
//  PerformanceShaders
//
//  Created by Pierre Hanna on 2017-10-28.
//  Copyright © 2017 Metal by Example. All rights reserved.
//

import Foundation
import simd

//
//  MBEMathUtilities.m
//  TextRendering
//
//  Created by Warren Moore on 11/10/14.
//  Copyright (c) 2014 Metal By Example. All rights reserved.
//



func random_float(min:Float, max:Float) ->Float
{
    return min + ( Float(arc4random()) / Float(UInt32.max) * (max - min))
}

func vector_orthogonal(v:float3) ->vector_float3
{
    // This algorithm is due to Sam Hocevar.
    return abs(v.x) > abs(v.z) ? vector_float3( -v.y, v.x, 0.0 ) : vector_float3( 0.0, -v.z, v.y )
}

func matrix_identity() ->float4x4
    {
        let X:float4 = float4( 1, 0, 0, 0 )
        let Y:float4 = float4( 0, 1, 0, 0 )
        let Z:float4 = float4( 0, 0, 1, 0 )
        let W:float4 = float4( 0, 0, 0, 1 )
        
        let identity:float4x4 = float4x4( X, Y, Z, W )
        
        return identity;
}

func matrix_rotation( axis:vector_float3,  angle:Float) ->float4x4
{
    let c:Float = cos(angle)
    let s:Float = sin(angle)
    
    var X = float4()
    X.x = axis.x * axis.x + (1 - axis.x * axis.x) * c
    X.y = axis.x * axis.y * (1 - c) - axis.z*s
    X.z = axis.x * axis.z * (1 - c) + axis.y * s
    X.w = 0.0;
    
    var Y = float4()
    Y.x = axis.x * axis.y * (1 - c) + axis.z * s
    Y.y = axis.y * axis.y + (1 - axis.y * axis.y) * c
    Y.z = axis.y * axis.z * (1 - c) - axis.x * s
    Y.w = 0.0;
    
    var Z = float4()
    Z.x = axis.x * axis.z * (1 - c) - axis.y * s;
    Z.y = axis.y * axis.z * (1 - c) + axis.x * s;
    Z.z = axis.z * axis.z + (1 - axis.z * axis.z) * c;
    Z.w = 0.0;
    
    var W = float4()
    W.x = 0.0;
    W.y = 0.0;
    W.z = 0.0;
    W.w = 1.0;
    
    let mat =  float4x4(X, Y, Z, W)
    return mat;
}

func matrix_translation( t:vector_float3) ->float4x4
{
    let X =  float4(1, 0, 0, 0)
    let Y =  float4(0, 1, 0, 0)
    let Z =  float4(0, 0, 1, 0)
    let W =  float4(t.x, t.y, t.z, 1)
    
    let mat = float4x4( X, Y, Z, W )
    
    return mat
}

func matrix_scale( s:vector_float3) ->float4x4
{
    let X =  float4(  s.x, 0,   0,   0)
    let Y =  float4(  0,   s.y, 0,   0)
    let Z =  float4(  0,   0,   s.z, 0)
    let W =  float4(  0,   0,   0,   1)
    
    let mat = float4x4( X, Y, Z, W )
    
    return mat;
}

func matrix_uniform_scale( s:Float) ->float4x4
{
    let X =  float4(s, 0, 0, 0)
    let Y =  float4(0, s, 0, 0)
    let Z =  float4(0, 0, s, 0)
    let W =  float4(0, 0, 0, 1)
    
    let mat = float4x4( X, Y, Z, W )
    
    return mat;
}

func matrix_perspective_projection(
                                aspect: Float,
                                fovy:   Float,
                                near:   Float,
                                far:    Float) ->float4x4
{
    let yScale:Float    =  1 / tan(fovy * 0.5)
    let xScale:Float    =  yScale / aspect
    let zRange:Float    =  far - near
    let zScale:Float    = -(far + near) / zRange
    let wzScale:Float   = -2 * far * near / zRange
    
    let P = float4( xScale, 0, 0, 0 )
    let Q = float4( 0, yScale, 0, 0 )
    let R = float4( 0, 0, zScale, -1 )
    let S = float4( 0, 0, wzScale, 0 )
    
    let mat = float4x4( P, Q, R, S )
    return mat;
}

func matrix_orthographic_projection(
                                left:   Float,
                                right:  Float,
                                top:    Float,
                                bottom: Float,
                                near:   Float = 0.0001,
                                far:    Float = 1) ->float4x4
{
    // default far near plane - division by zero check
    var _near:Float = near
    var _far:Float  = far
    if near == 0 { _near = 0.00001 }
    if far  == 0 { _far = 10.0 }
    
    // scale part
    let sx:Float = 2 / (right - left)               // 2/(1-(-1))
    let sy:Float = 2 / (top - bottom)               // 2/(1-(-1))
    let sz:Float = 1 / (_far - _near)               // 1/(1-0) - NOTE Metal z clip is [0,1], thus 1 (openGL z clip on the other hand is [-1,1])
    
    // translate vector
    let tx:Float = (right + left) / (left - right)  // (1+(-1)) / (-1-1)
    let ty:Float = (top + bottom) / (bottom - top)  // (1+(-1)) / (-1-1)
    let tz:Float = _near / (_far - _near)           // 0/(1-0)
    
    let col0 = float4(  sx,  0,   0,   0)
    let col1 = float4(  0,   sy,  0,   0)
    let col2 = float4(  0,   0,   sz,  0)
    let col3 = float4(  tx,  ty,  tz,  1)
    
    // set the columns
    let mat = float4x4( col0, col1, col2, col3 )
    return mat
}

func matrix_extract_linear(  mat:float4x4) ->float4x4
{
    var lin:float4x4    = mat;
    lin.columns.0.z     = 0;
    lin.columns.1.z     = 0;
    lin.columns.2.z     = 0;
    lin.columns.3       = float4( 0, 0, 0, 1 )
    return lin;
}

func construct_normalMatrix( modelViewMatrix:float4x4) ->float3x3
{
    var normalMatrix:float3x3 = float3x3()
    normalMatrix.columns.0      = float3(modelViewMatrix.columns.0.x, modelViewMatrix.columns.0.y, modelViewMatrix.columns.0.z)
    normalMatrix.columns.1      = float3(modelViewMatrix.columns.1.x, modelViewMatrix.columns.1.y, modelViewMatrix.columns.1.z)
    normalMatrix.columns.2      = float3(modelViewMatrix.columns.2.x, modelViewMatrix.columns.2.y, modelViewMatrix.columns.2.z)
    normalMatrix                = (normalMatrix.transpose).inverse
    
    return normalMatrix
}

