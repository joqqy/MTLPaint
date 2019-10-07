//
//  blitTools.swift
//  NavierStokes_Kernel
//
//  Created by Pierre Hanna on 2017-10-17.
//  Copyright © 2017 Pierre Hanna. All rights reserved.
//

import Foundation
import MetalKit

class blit
{
    static func tex_2_frameBuffer(
        mtkview:              MTKView,
        commandBuffer:        MTLCommandBuffer,
        tex:                  inout MTLTexture
        )
    {
        if  let currentDrawable = mtkview.currentDrawable
        {
            if #available(iOS 10.0, *)
            {
                guard(Int(mtkview.drawableSize.width) == tex.width && Int(mtkview.drawableSize.height) == tex.height) else { return () }
                
                let blit    = commandBuffer.makeBlitCommandEncoder()
                
                // FOR DEBUG PURPOSES ONLY
                blit?.label  = "label: blit_texture_2_frameBuffer"
                // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool
                blit?.pushDebugGroup("blit_texture_2_frameBuffer")
                
                let origin:MTLOrigin = MTLOriginMake(0,0,0)
                blit?.copy(
                    from:               tex,
                    sourceSlice:        0,
                    sourceLevel:        0,
                    sourceOrigin:       origin,
                    sourceSize:         MTLSizeMake(tex.width, tex.height, 1),
                    to:                 currentDrawable.texture,
                    destinationSlice:   0,
                    destinationLevel:   0,
                    destinationOrigin:  origin
                )

                // We're done encoding commands
                blit?.popDebugGroup()
                blit?.endEncoding()
            }
            else
            {
                // Fallback on earlier versions
                print("*** Could not create blit encoder ***")
            }
        }
    }
    
    static func frameBuffer_2_tex(
        mtkview:           MTKView,
        commandBuffer:     MTLCommandBuffer,
        tex:               inout MTLTexture
        )
    {
        if let currentDrawable = mtkview.currentDrawable //(mtkview.layer as? CAMetalLayer)?.nextDrawable() // not the second option return another drawable (not the written to framebuffer!)
        {
            if #available(iOS 10.0, *)
            {
                guard(Int(mtkview.drawableSize.width) == tex.width && Int(mtkview.drawableSize.height) == tex.height) else { return () }
                
                let blit    = commandBuffer.makeBlitCommandEncoder()
                
                // FOR DEBUG PURPOSES ONLY
                blit?.label  = "label: blit_frameBuffer_2_tex"
                // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool
                blit?.pushDebugGroup("blit_frameBuffer_2_tex")

                
                let origin:MTLOrigin = MTLOriginMake(0,0,0)
                blit?.copy(
                    from:               currentDrawable.texture,
                    sourceSlice:        0,
                    sourceLevel:        0,
                    sourceOrigin:       origin,
                    sourceSize:         MTLSizeMake(tex.width, tex.height, 1),
                    to:                 tex,
                    destinationSlice:   0,
                    destinationLevel:   0,
                    destinationOrigin:  origin
                )
                
                // We're done encoding commands
                blit?.popDebugGroup()
                blit?.endEncoding()
            }
            else
            {
                // Fallback on earlier versions
                print("*** Could not create blit encoder ***")
            }
        }
    }
    
    static func frameBuffer_2_tex_CAMetalLayer(
        CA_MetalLayer:     CAMetalLayer,
        commandBuffer:     MTLCommandBuffer,
        tex:               inout MTLTexture
        )
    {
        if  let currentDrawable = CA_MetalLayer.nextDrawable()
        {
            if #available(iOS 10.0, *)
            {
                guard(Int(CA_MetalLayer.drawableSize.width) == tex.width && Int(CA_MetalLayer.drawableSize.height) == tex.height) else { return () }
                
                let blit = commandBuffer.makeBlitCommandEncoder()
                
                // FOR DEBUG PURPOSES ONLY
                blit?.label = "labl: blit_frameBuffer_2_tex"
                // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool
                blit?.pushDebugGroup("blit_frameBuffer_2_tex")

                let origin:MTLOrigin = MTLOriginMake(0,0,0)
                blit?.copy(
                    from:               currentDrawable.texture,
                    sourceSlice:        0,
                    sourceLevel:        0,
                    sourceOrigin:       origin,
                    sourceSize:         MTLSizeMake(tex.width, tex.height, 1),
                    to:                 tex,
                    destinationSlice:   0,
                    destinationLevel:   0,
                    destinationOrigin:  origin
                )

                // We're done encoding commands
                blit?.popDebugGroup()
                blit?.endEncoding()
            }
            else
            {
                // Fallback on earlier versions
                print("*** Could not create blit encoder ***")
            }
        }
    }
    
    static func texA_2_texB(
        mtkview:            MTKView,
        commandBuffer:      MTLCommandBuffer,
        src:               inout MTLTexture,
        dst:               inout MTLTexture
        )
    {
        if #available(iOS 10.0, *)
        {
            guard(dst.width == src.width && dst.height == src.height) else { return () }
            
            let blit    = commandBuffer.makeBlitCommandEncoder()
            
            // FOR DEBUG PURPOSES ONLY
            blit?.label  = "label: blit_texA_2_texB"
            // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool
            blit?.pushDebugGroup("blit_texA_2_texB")
            
            let origin:MTLOrigin = MTLOriginMake(0,0,0)
            blit?.copy(
                from:               src,
                sourceSlice:        0,
                sourceLevel:        0,
                sourceOrigin:       origin,
                sourceSize:         MTLSizeMake(src.width, src.height, 1),
                to:                 dst,
                destinationSlice:   0,
                destinationLevel:   0,
                destinationOrigin:  origin
            )
            
            // We're done encoding commands
            blit?.popDebugGroup()
            blit?.endEncoding()
        }
        else
        {
            // Fallback on earlier versions
            print("*** Could not create blit encoder ***")
        }
    }
    
    static func texDepth_2_shadowTex(
        mtkview:           MTKView,
        commandBuffer:     MTLCommandBuffer,
        src:               inout MTLTexture,
        dst:               MTLTexture
        )
    {
        if #available(iOS 10.0, *)
        {
            guard(dst.width == src.width && dst.height == src.height) else { return () }
            
            let blit    = commandBuffer.makeBlitCommandEncoder()
            
            // FOR DEBUG PURPOSES ONLY
            blit?.label  = "label: texDepth_2_shadowTex"
            // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool
            blit?.pushDebugGroup("texDepth_2_shadowTex")
            
            let origin:MTLOrigin = MTLOriginMake(0,0,0)
            blit?.copy(
                from:               src,
                sourceSlice:        0,
                sourceLevel:        0,
                sourceOrigin:       origin,
                sourceSize:         MTLSizeMake(Int(mtkview.drawableSize.width), Int(mtkview.drawableSize.height), 1),
                to:                 dst,
                destinationSlice:   0,
                destinationLevel:   0,
                destinationOrigin:  origin
            )

            // We're done encoding commands===
            blit?.popDebugGroup()
            blit?.endEncoding()
        }
        else
        {
            // Fallback on earlier versions
            print("*** Could not create blit encoder ***")
        }
    }

    static func texDepth_2_buffer(
        mtkview:           MTKView,
        commandBuffer:     MTLCommandBuffer,
        src:               inout MTLTexture,
        dst:               MTLBuffer
        )
    {
        if #available(iOS 10.0, *)
        {
            guard(Int(mtkview.drawableSize.width) == src.width && Int(mtkview.drawableSize.height) == src.height) else { return () }
            
            let blit    = commandBuffer.makeBlitCommandEncoder()
            
            // FOR DEBUG PURPOSES ONLY
            blit?.label  = "label: texDepth_2_buffer"
            // Push a debug group allowing us to identify render commands in the GPU Frame Capture tool
            blit?.pushDebugGroup("texDepth_2_buffer")
            
            let bytesPerPixel:Int   = 4
            let bytesPerRow:Int     = Int(mtkview.drawableSize.width) * bytesPerPixel
            let bytesPerImage:Int   = bytesPerRow * Int(mtkview.drawableSize.height)
            
            blit?.copy(
                from: src,
                sourceSlice: 0,
                sourceLevel: 0,
                sourceOrigin: MTLOriginMake(0, 0, 0),
                sourceSize: MTLSizeMake(src.width, src.height, 1),
                to: dst,
                destinationOffset: 0,
                destinationBytesPerRow: bytesPerRow,
                destinationBytesPerImage: bytesPerImage,
                options: MTLBlitOption.depthFromDepthStencil)
            
            // We're done encoding commands
            blit?.popDebugGroup()
            blit?.endEncoding()
        }
        else
        {
            // Fallback on earlier versions
            print("*** Could not create blit encoder ***")
        }
    }
}
