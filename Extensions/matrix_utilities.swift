//
//  test.swift
//  NavierStokes_Kernel
//
//  Created by Pierre Hanna on 2017-08-30.
//  Copyright © 2017 Pierre Hanna. All rights reserved.
//

import Foundation
import simd
import GLKit

enum MBEScalingMode
{
    case MBEImageScalingModeAspectFit
    case MBEImageScalingModeAspectFill
    case MBEImageScalingModeScaleToFill
    case MBEImageScalingModeDontResize
}

class matrixGenerator
{
    static let lookAtMatrix_simd = simd_float4x4.makeLookAt(
        0,      0,      0.5,
        0,      0,      0,
        0,      1.0,    0
    )
    
    static func makeOrthographicMatrix_simd(
        left:   Float,
        right:  Float,
        bottom: Float,
        top:    Float,
        near:   Float,
        far:    Float
        ) -> simd_float4x4
        
    {
        let projOrtho = float4x4.makeOrtho(
            left,
            right,
            bottom,
            top,
            near,
            far
        )
        
        return projOrtho
        
//        let left:Float      = 0.0
//        let right:Float     = Float(g_width)
//        let bottom:Float    = Float(g_height)
//        let top:Float       = 0.0
//
//        // Metal adjustment left multiply matrix
//        let metalM:GLKMatrix4 = GLKMatrix4Make(
//            1.0, 0.0, 0.0, 0.0,         //column1
//            0.0, 1.0, 0.0, 0.0,         //column2
//            0.0, 0.0, 0.5, 0.0,         //column3
//            0.0, 0.0, 0.5, 1.0          //column4
//        )
//
//        let ral     = right + left
//        let rsl     = right - left
//        let tab     = top + bottom
//        let tsb     = top - bottom
//        let fan     = far + near
//        let fsn     = far - near
//
//        let m = GLKMatrix4Make(
//            2.0/rsl,    0.0,        0.0,            0.0,    //column1
//            0.0,        2.0/tsb,    0.0,            0.0,    //column2
//            0.0,        0.0,        -2.0 / fsn,     0.0,    //column3
//            -ral/rsl,   -tab/tsb,   -fan/fsn,       1.0     //column4
//        )
//
//        var matrix:simd_float4x4 = simd_float4x4()
//
//        matrix[0][0] = GLKMatrix4Multiply(metalM, m).m00
//        matrix[0][1] = GLKMatrix4Multiply(metalM, m).m01
//        matrix[0][2] = GLKMatrix4Multiply(metalM, m).m02
//        matrix[0][3] = GLKMatrix4Multiply(metalM, m).m03
//
//        matrix[1][0] = GLKMatrix4Multiply(metalM, m).m10
//        matrix[1][1] = GLKMatrix4Multiply(metalM, m).m11
//        matrix[1][2] = GLKMatrix4Multiply(metalM, m).m12
//        matrix[1][3] = GLKMatrix4Multiply(metalM, m).m13
//
//        matrix[2][0] = GLKMatrix4Multiply(metalM, m).m20
//        matrix[2][1] = GLKMatrix4Multiply(metalM, m).m21
//        matrix[2][2] = GLKMatrix4Multiply(metalM, m).m22
//        matrix[2][3] = GLKMatrix4Multiply(metalM, m).m23
//
//        matrix[3][0] = GLKMatrix4Multiply(metalM, m).m30
//        matrix[3][1] = GLKMatrix4Multiply(metalM, m).m31
//        matrix[3][2] = GLKMatrix4Multiply(metalM, m).m32
//        matrix[3][3] = GLKMatrix4Multiply(metalM, m).m33
//
//        return matrix
    }
    
    //=========== Perspective Projection Matrix ===========
    static func matrix_perspective_projection(
        _ aspect:                       Float32,
        fieldOfViewYRadians fovy:       Float32,
        near:                           Float32,
        far:                            Float32
        ) -> float4x4
    {
        var mat     = float4x4()
        
        let yScale  = 1 / tan(fovy * 0.5)
        let xScale  = yScale / aspect
        let zRange  = far - near
        let zScale  = -(far + near) / zRange
        let wzScale = -2 * far * near / zRange
        
        mat[0].x    = xScale
        mat[1].y    = yScale
        mat[2].z    = zScale
        mat[2].w    = -1
        mat[3].z    = wzScale
        
        return mat;
    }
    
    //=========== Rotation Matrix ===========
    static func matrix_rotation_about_axis(
        _ axis:                 float4,
        byAngleRadians angle:   Float32
        ) -> float4x4
    {
        var mat     = float4x4()
        
        let c       = cos(angle)
        let s       = sin(angle)
        
        mat[0].x    = c + axis.x * axis.x * (1 - c)
        mat[0].y    = (axis.y * axis.x) * (1 - c) + axis.z * s
        mat[0].z    = (axis.z * axis.x) - axis.y * s
        
        mat[1].x    = (axis.x * axis.y) * (1 - c) - axis.z * s
        mat[1].y    = c + axis.y * axis.y * (1 - c)
        mat[1].z    = (axis.z * axis.y) + axis.x * s
        
        mat[2].x    = (axis.x * axis.z) * (1 - c) + axis.y * s
        mat[2].y    = (axis.y * axis.z) * (1 - c) - axis.x * s
        mat[2].z    = c + axis.z * axis.z * (1 - c)
        
        mat[3].w    = 1
        
        return mat
    }
    
    //=========== Translation Matrix ===========
    static func matrix_translation(
        _ translation: float3
        ) -> float4x4
    {
        var mat     = float4x4()
        
        mat[0][0]   = 1.0
        mat[1][1]   = 1.0
        mat[2][2]   = 1.0
        mat[3][0]   = translation.x
        mat[3][1]   = translation.y
        mat[3][2]   = translation.z
        mat[3][3]   = 1.0
        
        return mat
    }
    
    static func scaleMatrixForScalingMode
    (
        scalingMode: MBEScalingMode,
        textureSize: CGSize,
        viewSize: CGSize
    ) -> matrix_float2x2
    {
        let twidth = Float(textureSize.width)
        let theight = Float(textureSize.height)
        
        let vwidth = Float(viewSize.width)
        let vheight = Float(viewSize.height)
        
        let imageAspect:Float = twidth / theight
        let viewAspect:Float = vwidth / vheight
        
        var matrix = matrix_float2x2()
        
        switch scalingMode
        {
            
        case .MBEImageScalingModeScaleToFill:
            return matrix
            
        case .MBEImageScalingModeAspectFit:
            
            if (imageAspect < viewAspect)
            {
                matrix.columns.0.x = (imageAspect / viewAspect);
            }
            else
            {
                matrix.columns.1.y = (viewAspect / imageAspect);
            }
            return matrix;
            
        case .MBEImageScalingModeAspectFill:
            
            if (imageAspect > viewAspect)
            {
                matrix.columns.0.x = (imageAspect / viewAspect);
            }
            else
            {
                matrix.columns.1.y = (viewAspect / imageAspect);
            }
            return matrix;
            
        case .MBEImageScalingModeDontResize:
            
            matrix.columns.0.x = Float((textureSize.width / viewSize.width))
            matrix.columns.1.y = Float((textureSize.height / viewSize.height))
            return matrix;
            
        }
    }
}

