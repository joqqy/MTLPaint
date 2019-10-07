/**
 * Copyright (c) 2016 Pierre Hanna LLC
 */

import Foundation
import simd
import GLKit

extension simd_float4x4
{
//    init()
//    {
//        self = unsafeBitCast(GLKMatrix4Identity, to: simd_float4x4.self)
//    }
    
    mutating func getVec3(column:Int) ->float3
    {
        let col:float4 = self[column]
        return float3(col.x, col.y, col.z)
    }
    
    static func makeScale(
        _ x: Float,
        _ y: Float,
        _ z: Float
        ) -> float4x4
    {
        return unsafeBitCast(GLKMatrix4MakeScale(x, y, z), to: simd_float4x4.self)
    }
    
    static func makeRotate(
        _ radians: Float,
        _ x: Float,
        _ y: Float,
        _ z: Float
        ) -> float4x4
    {
        return unsafeBitCast(GLKMatrix4MakeRotation(radians, x, y, z), to: simd_float4x4.self)
    }
    
    static func makeTranslation(
        _ x: Float,
        _ y: Float,
        _ z: Float
        ) -> float4x4
    {
        return unsafeBitCast(GLKMatrix4MakeTranslation(x, y, z), to: simd_float4x4.self)
    }
    
    static func makePerspectiveViewAngle(
        _ fovyRadians:  Float,
        aspectRatio:    Float,
        nearZ:          Float,
        farZ:           Float
        ) -> simd_float4x4
    {
        var q       = unsafeBitCast(GLKMatrix4MakePerspective(fovyRadians, aspectRatio, nearZ, farZ), to: simd_float4x4.self)
        let zs      = farZ / (nearZ - farZ)
        q[2][2]     = zs
        q[3][2]     = zs * nearZ
        
        return q
    }
    
    static func makeFrustum(
        _ left:     Float,
        _ right:    Float,
        _ bottom:   Float,
        _ top:      Float,
        _ nearZ:    Float,
        _ farZ:     Float
        ) -> float4x4
    {
        return unsafeBitCast(GLKMatrix4MakeFrustum(left, right, bottom, top, nearZ, farZ), to: simd_float4x4.self)
    }
    
    static func makeOrtho(
        _ left: Float,
        _ right: Float,
        _ bottom: Float,
        _ top: Float,
        _ nearZ: Float,
        _ farZ: Float
        ) -> simd_float4x4
    {
        return unsafeBitCast(
            GLKMatrix4MakeOrtho(
                left,
                right,
                bottom,
                top,
                nearZ,
                farZ),
            to: simd_float4x4.self
        )
    }
    
    static func makeLookAt(
        _ eyeX: Float,
        _ eyeY: Float,
        _ eyeZ: Float,
        _ centerX: Float,
        _ centerY: Float,
        _ centerZ: Float,
        _ upX: Float,
        _ upY: Float,
        _ upZ: Float
        ) -> simd_float4x4
    {
        return unsafeBitCast(
            GLKMatrix4MakeLookAt(
                eyeX,
                eyeY,
                eyeZ,
                centerX,
                centerY,
                centerZ,
                upX,
                upY,
                upZ
        ), to: simd_float4x4.self)
    }
    
    
    mutating func scale(
        _ x: Float,
        y:  Float,
        z:  Float)
    {
        self = self * simd_float4x4.makeScale(x, y, z)
    }
    
    mutating func rotate(
        _ radians:  Float,
        x:          Float,
        y:          Float,
        z:          Float
        )
    {
        self = simd_float4x4.makeRotate(radians, x, y, z) * self
    }
    
    mutating func rotateAroundX(
        _ x:    Float,
        y:      Float,
        z:      Float
        )
    {
        var rotationM   = simd_float4x4.makeRotate(x, 1, 0, 0)
        rotationM       = rotationM * float4x4.makeRotate(y, 0, 1, 0)
        rotationM       = rotationM * float4x4.makeRotate(z, 0, 0, 1)
        self            = self * rotationM
    }
    
    mutating func translate(
        _ x:    Float,
        y:      Float,
        z:      Float
        )
    {
        self = self * simd_float4x4.makeTranslation(x, y, z)
    }
    
    static func numberOfElements() -> Int
    {
        return 16
    }
    
    static func degrees(toRad angle: Float) -> Float
    {
        return Float(Double(angle) * Double.pi / 180)
    }
    
    mutating func multiplyLeft(_ matrix: simd_float4x4)
    {
        let glMatrix1   = unsafeBitCast(matrix, to: GLKMatrix4.self)
        let glMatrix2   = unsafeBitCast(self, to: GLKMatrix4.self)
        let result      = GLKMatrix4Multiply(glMatrix1, glMatrix2)
        self            = unsafeBitCast(result, to: simd_float4x4.self)
    }
    
    //Nv
    nonmutating func _11() ->Float
    {
        return self.columns.0.x
    }
    nonmutating func _12() ->Float
    {
        return self.columns.0.y
    }
    nonmutating func _13() ->Float
    {
        return self.columns.0.z
    }
    nonmutating func _14() ->Float
    {
        return self.columns.0.w
    }
    
    nonmutating func _21() ->Float
    {
        return self.columns.1.x
    }
    nonmutating func _22() ->Float
    {
        return self.columns.1.y
    }
    nonmutating func _23() ->Float
    {
        return self.columns.1.z
    }
    nonmutating func _24() ->Float
    {
        return self.columns.1.w
    }
    
    nonmutating func _31() ->Float
    {
        return self.columns.2.x
    }
    nonmutating func _32() ->Float
    {
        return self.columns.2.y
    }
    nonmutating func _33() ->Float
    {
        return self.columns.2.z
    }
    nonmutating func _34() ->Float
    {
        return self.columns.2.w
    }
    
    nonmutating func _41() ->Float
    {
        return self.columns.3.x
    }
    nonmutating func _42() ->Float
    {
        return self.columns.3.y
    }
    nonmutating func _43() ->Float
    {
        return self.columns.3.z
    }
    nonmutating func _44() ->Float
    {
        return self.columns.3.w
    }
    
    mutating func _11(_ val: Float)
    {
        self.columns.0.x = val
    }
    mutating func _12(_ val: Float)
    {
        self.columns.0.y = val
    }
    mutating func _13(_ val: Float)
    {
        self.columns.0.z = val
    }
    mutating func _14(_ val: Float)
    {
        self.columns.0.w = val
    }
    
    mutating func _21(_ val: Float)
    {
        self.columns.1.x = val
    }
    mutating func _22(_ val: Float)
    {
        self.columns.1.y = val
    }
    mutating func _23(_ val: Float)
    {
        self.columns.1.z = val
    }
    mutating func _24(_ val: Float)
    {
        self.columns.1.w = val
    }
    
    mutating func _31(_ val: Float)
    {
        self.columns.2.x = val
    }
    mutating func _32(_ val: Float)
    {
        self.columns.2.y = val
    }
    mutating func _33(_ val: Float)
    {
        self.columns.2.z = val
    }
    mutating func _34(_ val: Float)
    {
        self.columns.2.w = val
    }
    
    mutating func _41(_ val: Float)
    {
        self.columns.3.x = val
    }
    mutating func _42(_ val: Float)
    {
        self.columns.3.y = val
    }
    mutating func _43(_ val: Float)
    {
        self.columns.3.z = val
    }
    mutating func _44(_ val: Float)
    {
        self.columns.3.w = val
    }
    
    mutating func setIdentity()
    {
        self = float4x4(1)
    }
}










