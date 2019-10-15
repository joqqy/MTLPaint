//
//  PaintingView.swift
//  MTLPaint
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/1/4.
//  Migrated to Metal by OOPer in cooperation with shlab.jp, on 2019/4/26.
//

import UIKit
import MetalKit

enum LoadAction {
    case load
    case clear(red: Double, green: Double, blue: Double, alpha: Double)
}

enum EInterpolationMethod: Int {
    
    /// The raw value is the number of points to check for before trimming
    case hermite = 1
    case catmullRom = 3
}

// MARK: - Shaders
let PROGRAM_POINT = 0

let UNIFORM_MVP = 0
let UNIFORM_POINT_SIZE = 1
let UNIFORM_VERTEX_COLOR = 2

struct ProgramInfo {
    var vert: String
    var frag: String
    var uniform: [MTLBuffer?] = []
    var pipelineState: MTLRenderPipelineState!
}

var program: [ProgramInfo] = [
    ProgramInfo(vert: "PointVertex", frag: "PointFragment", uniform: [], pipelineState: nil),     // PROGRAM_POINT
]
let NUM_PROGRAMS = program.count


// MARK: - Texture

struct TextureInfo {
    var texture: MTLTexture?
    var sampler: MTLSamplerState?
    
    init() {
        texture = nil
        sampler = nil
    }
}

enum ESpliningType {
    
    case bezLine
    case hermite
    case catmullRom
    case SadunSmoothing
}

struct NControlPoints {
    
    static let bezLine = 2
    static let hermite = 2
    static let catmullRom = 4
    static let SadunSmoothing = 4
}


class PaintingView: MTKView {
    
    private var metalDevice: MTLDevice = MTLCreateSystemDefaultDevice()!
    private var metalCommandQueue: MTLCommandQueue?
    private var viewport: MTLViewport!
    private var renderTargetTexture: MTLTexture!

    var coalescedCount: Int = 0
    var smoothCurve: Bool = false
    var simplify: Bool = true
    
    // MARK: - The pixel dimensions of the backbuffer

    private var backingWidth: Int = 0
    private var backingHeight: Int = 0
    
    private var brushTexture: TextureInfo! // brush texture
    private var brushColor: [Float] = [0, 0, 0, 0] // brush color

    private var needsErase: Bool = false
    private var initialized: Bool = false

    var points: [CGPoint] = []
    
    
    var prevLocation: CGPoint? = nil
    
    var vertBuffer: MTLBuffer? = nil

    // Implement this to override the default layer class (which is [CALayer class]).
    // We do this so that our view will be backed by a layer that is capable of Metal rendering.
    override class var layerClass : AnyClass {
        return CAMetalLayer.self
    }

    // The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
    required init(coder: NSCoder) {
        
        super.init(coder: coder)
        
        self.device = metalDevice
        self.metalCommandQueue = self.device?.makeCommandQueue()
        
        let metalLayer = self.layer as! CAMetalLayer
        metalLayer.framebufferOnly = false
        metalLayer.isOpaque = true
        metalLayer.pixelFormat = .bgra8Unorm

        // Set the view's scale factor as you wish
        self.contentScaleFactor = UIScreen.main.scale

        // Make sure to start with a cleared buffer
        needsErase = true
    }

    // If our view is resized, we'll be asked to layout subviews.
    // This is the perfect opportunity to also update the framebuffer so that it is
    // the same size as our display area.
    override func layoutSubviews() {

        if !initialized {
            initialized = initMetal()
        } else {
            self.resize(from: self.layer as! CAMetalLayer)
        }

        // Clear the framebuffer the first time it is allocated
        if needsErase {
            self.erase()
            needsErase = false
        }
    }

    private func setupShaders() {
        
        let defaultLibrary = metalDevice.makeDefaultLibrary()!
        
        for i in 0 ..< NUM_PROGRAMS {
            
            let vertexProgram = defaultLibrary.makeFunction(name: program[i].vert)!
            let fragmentProgram = defaultLibrary.makeFunction(name: program[i].frag)!

            let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
            pipelineStateDescriptor.vertexFunction = vertexProgram
            pipelineStateDescriptor.fragmentFunction = fragmentProgram
            pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

            // Enable blending and set a blending function appropriate for premultiplied alpha pixel data
            pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
            pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
            pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
            pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
            pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
            pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

            program[i].pipelineState = try! metalDevice.makeRenderPipelineState(descriptor: pipelineStateDescriptor)

            // MARK: - Set constant/initalize uniforms
            if i == PROGRAM_POINT {

                // MARK: - viewing matrices
                print(backingWidth, backingHeight)
                let projectionMatrix = float4x4.orthoLeftHand(0, backingWidth.f, 0, backingHeight.f, -1, 1)
                let modelViewMatrix = float4x4.identity
                var MVPMatrix = projectionMatrix * modelViewMatrix

                let uniformMVP = metalDevice.makeBuffer(bytes: &MVPMatrix, length: MemoryLayout<float4x4>.size)
                
                // MARK: - point size
                var pointSize = (brushTexture.texture?.width.f ?? 0) / kBrushScale.f
                let uniformPointSize = metalDevice.makeBuffer(bytes: &pointSize, length: MemoryLayout<Float>.size)

                // MARK: - initialize brush color
                let uniformVertexColor = metalDevice.makeBuffer(bytes: brushColor, length: MemoryLayout<Float>.size * brushColor.count)
                
                program[i].uniform = [uniformMVP, uniformPointSize, uniformVertexColor]
            }
        }
    }

    // Create a texture from an image
    private func texture(fromName name: String) -> TextureInfo {
        
        var texture = TextureInfo()

        // First create a UIImage object from the data in a image file, and then extract the Core Graphics image
        let brushImage = UIImage(named: name)?.cgImage

        // Get the width and height of the image
        let width: size_t = brushImage!.width
        let height: size_t = brushImage!.height

        // Make sure the image exists
        if brushImage != nil {
            
            // Allocate  memory needed for the bitmap context
            var brushData = [UInt8](repeating: 0, count: width * height * 4)
            // Use  the bitmatp creation function provided by the Core Graphics framework.
            let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
            let brushContext = CGContext(data: &brushData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: (brushImage?.colorSpace!)!, bitmapInfo: bitmapInfo)
            // After you create the context, you can draw the  image to the context.
            brushContext?.draw(brushImage!, in: CGRect(x: 0.0, y: 0.0, width: width.g, height: height.g))
            
            // You don't need the context at this point, so you need to release it to avoid memory leaks.
            //### ARC manages
            let loader = MTKTextureLoader(device: metalDevice)
            do {
                texture.texture = try loader.newTexture(cgImage: brushContext!.makeImage()!)
            } catch {
                print(error)
                return texture
            }
            // Set the texture parameters to use a minifying filter and a linear filer (weighted average)
            let samplerDescriptor = MTLSamplerDescriptor()
            samplerDescriptor.minFilter = .linear
            texture.sampler = metalDevice.makeSamplerState(descriptor: samplerDescriptor)
        }

        return texture
    }

    @discardableResult
    private func initMetal() -> Bool {

        backingWidth = Int(self.bounds.width * self.contentScaleFactor)
        backingHeight = Int(self.bounds.height * self.contentScaleFactor)

        // Setup the view port in Pixels
        viewport = MTLViewport(originX: 0, originY: 0, width: backingWidth.d, height: backingHeight.d, znear: 0, zfar: 1)

        // Load the brush texture
        brushTexture = self.texture(fromName: "Particle.png")

        // Load shaders
        self.setupShaders()
        
        return true
    }

    @discardableResult
    private func resize(from layer: CAMetalLayer) -> Bool {

        //### Set nil to refresh renderTargetTexture
        renderTargetTexture = nil
        backingWidth = Int(self.bounds.width * self.contentScaleFactor)
        backingHeight = Int(self.bounds.height * self.contentScaleFactor)

        // Update projection matrix
        let projectionMatrix = float4x4.orthoLeftHand(0, backingWidth.f, 0, backingHeight.f, -1, 1)
        let modelViewMatrix = float4x4.identity // this sample uses a constant identity modelView matrix
        var MVPMatrix = projectionMatrix * modelViewMatrix

       
        let uniformMVP = metalDevice.makeBuffer(bytes: &MVPMatrix, length: MemoryLayout<float4x4>.size)
        program[PROGRAM_POINT].uniform[UNIFORM_MVP] = uniformMVP

        // Update viewport
        viewport = MTLViewport(originX: 0, originY: 0, width: backingWidth.d, height: backingHeight.d, znear: 0, zfar: 1)

        return true
    }
  
    private static let defaultLoadAction: LoadAction = .clear(red: 0, green: 0, blue: 0, alpha: 0)
    
    private func drawInNextDrawable(loadAction: LoadAction = defaultLoadAction,
                                    drawing: (MTLRenderCommandEncoder) -> Void) {
        
        guard let drawable = (self.layer as! CAMetalLayer).nextDrawable() else {
            return
        }

        if renderTargetTexture == nil {
            renderTargetTexture = createRenderTargetTexture(from: drawable.texture)
        }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        let attachment = renderPassDescriptor.colorAttachments[0]!

        attachment.texture = self.renderTargetTexture
        switch loadAction {
            
        case .load:
            attachment.loadAction = .load
            
        case let .clear(red: red, green: green, blue: blue, alpha: alpha):
            // Clear the buffer
            attachment.loadAction = .clear
            attachment.clearColor = MTLClearColor(red: red, green: green, blue: blue, alpha: alpha)
        }
        attachment.storeAction = .store

        guard let commandBuffer = metalCommandQueue?.makeCommandBuffer() else {
            return
        }
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                return
        }

        drawing(renderEncoder)
        renderEncoder.endEncoding()
        
        
        
        // MARK: - Blit render target to drawable
        let blit = commandBuffer.makeBlitCommandEncoder()!
        
        let sourceSize = MTLSize(width: drawable.texture.width,
                                 height: drawable.texture.height,
                                 depth: 1)
        
        blit.copy(from: renderTargetTexture,
                  sourceSlice: 0,
                  sourceLevel: 0,
                  sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                  sourceSize: sourceSize,
                  to: drawable.texture,
                  destinationSlice: 0,
                  destinationLevel: 0,
                  destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        blit.endEncoding()
       
        
        // MARK: - Commit and Display the buffer
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
    }

    // Opaque dots
//    let kBrushOpacity = (1.0 / 1.0)
//    let kBrushPixelStep = 20.0 // :n amount of pixels between any two points, 1 means 1 pixel between points
//    let kBrushScale = 20.0
        
    // bigger transparent brush
    let kBrushOpacity = (1.0 / 25.0)
    let kBrushPixelStep = 1.0 // :n amount of pixels between any two points, 1 means 1 pixel between points
    let kBrushScale = 2.0
    
    // MARK: - CONSTANTS:
    
    /// interpolate between final points
    private var interpolateBetweenPoints: Bool = true // :true
    /// use coalesced
    private var useCoalescedTouches: Bool = true // :true
        var ctr: Int = 0
        let midpointLine: Bool = false
    /// use predicted
    private var usePredictedTouches: Bool = false // :false
    /// spline
    private var splinePoints: Bool = false // :true
    /// splining type
    private var eSpliningType: ESpliningType = .catmullRom
    
    
    // MARK: - Draws a line onscreen based on where the user touches
    private func renderLine(points: [CGPoint]) {
        
        // MARK: - Allocate vertex array buffer for GPU
        var pointsFromPath: [SIMD2<Float>] = []
            
        //--------------------------------------------------------------
        // MARK: - Guard check the [CGPoint] array collected from touch
        //--------------------------------------------------------------
        switch (self.eSpliningType) {
                
        case .bezLine:
            guard self.points.count > NControlPoints.bezLine else { return }
 
        case .catmullRom, .SadunSmoothing:
            guard self.points.count > NControlPoints.catmullRom else { return }
            
        case .hermite:
            guard self.points.count > NControlPoints.hermite else { return }
            
        @unknown default:
            break
        }
            
        //--------------------------------------------------------------
        // MARK: Spline/Bezier/Smoothen the collected [CGPoint] array
        //--------------------------------------------------------------
        // local copy the global points
        let touchPoints = self.points

        if self.splinePoints {
                
            var strokePath: UIBezierPath? = UIBezierPath()

            switch (self.eSpliningType) {
                    
            case .catmullRom:
                
                //------------------------------------
                // MARK: - Spline
                //------------------------------------
                strokePath = INTERP.interpolateCGPointsWithCatmullRom(
                    pointsAsNSValues: touchPoints,
                    closed: false,
                    alpha: 0.5)
                
                //------------------------------------
                // MARK: - Trim origial touch cache
                //------------------------------------
                if self.points.count >= NControlPoints.catmullRom {
                    
                    /**
                     Note that the difference between hermite and catmull-rom is that with hermite, we have to explicityly supply the tangents to p0 and p1 (start and end point resp.)
                     The last point is shared for each new segment
                        
                     Hermite  (the tangents lie on p0 and p1)
                     segment 1:  p0---------p1
                     segment 2:                  p0---------p1
                     
                     With catmull-rom, we need 4 points (p0, p1, p2 and p3) But we do not need to explicitly supply any tangent. The formula creates a segment between p1 and p3,
                     and calculates the two tangents automaticallyusing p0 and p2 and p1 and p3 respectively.
                     So you see, for each new segment, we need the previous 3 points, ie. last 3 points are shared for each new segment
                     
                     Catmull-Rom  (the tangents lie on p1 and p2)
                     segment 1:   p0          p1---------p2             p3
                     segment 2:                 p0             p1---------p2            p3
                     and so on . . .                     
                     */
                    
                    let point1 = self.points[self.points.count - 3]
                    let point2 = self.points[self.points.count - 2]
                    let point3 = self.points.last!

                    // remake the array using the last point
                    self.points = [point1, point2, point3]
                }
                    
            case .bezLine:
                    
                //------------------------------------
                // MARK: - No spline, just a line between two points
                //------------------------------------
                if touchPoints.count >= NControlPoints.bezLine {
                    for i in 0 ..< touchPoints.count - 1 {
                        strokePath?.move(to: touchPoints[i]) // start point
                        strokePath?.addLine(to: touchPoints[i+1]) // end point
                    }
                }
                
                //------------------------------------
                // MARK: - Trim origial touch cache
                //------------------------------------
                if self.points.count >= NControlPoints.catmullRom {
                    let lastPoint = self.points.last!
                    // remake the array using the last point
                    self.points = [lastPoint]
                }
     
            case .SadunSmoothing:
                    
                //------------------------------------
                // MARK: - Spline
                //------------------------------------
                for i in 0 ..< touchPoints.count-1 {
                    strokePath?.move(to: touchPoints[i]) // start point
                    strokePath?.addLine(to: touchPoints[i+1])
                }
                // MARK: - Spline/Bezier/Smoothen the collected [CGPoint] array (Erica Sadun's version)
                if smoothCurve {
                    /// smoothen
                    strokePath?.smoothened(granularity: 1) // smoothen test
                }
                
                //------------------------------------
                // MARK: - Trim origial touch cache
                //------------------------------------
                if self.points.count >= NControlPoints.SadunSmoothing {
                    let lastPoint = self.points.last!
                    // remake the array using the last point
                    self.points = [lastPoint]
                }
                    
            case .hermite:
                               
                //------------------------------------
                // MARK: - Spline
                //------------------------------------
                strokePath = INTERP.interpolateCGPointsWithHermite(points: touchPoints, closed: false)
                /// - Remark: Flexmonkey version
                //strokePath?.interpolatePointsWithHermite(interpolationPoints: touchPoints)
                
                //------------------------------------
                // MARK: - Trim origial touch cache
                //------------------------------------
                if self.points.count >= NControlPoints.hermite {
                    let lastPoint = self.points.last!
                    // remake the array using the last point
                    self.points = [lastPoint]
                }
            }

            
            //--------------------------------------------------------------
            // MARK: - extract points from curve/spline
            //--------------------------------------------------------------
            if let strokePath = strokePath {
                pointsFromPath = self.extractPoints_fromUIBezierPath_f2(strokePath)!
            }
                
                
        } else {
            
            // MARK: - No splining, just extract the CGPoints into whatever format is needed
            pointsFromPath = self.points.map { $0.f2 * 2.0 }
            
            //------------------
            // MARK: - Trim origial touch cache
            //------------------
            let lastPoint = self.points.last!
            // remake the array using the last point
            self.points = [lastPoint]
        }
            
            /**
             So I believe this only works for curves whose points are known ahead of time and do not change!
             We get weird funky chaos, and I believe it is because we are drawing continuously.
             If so, then this library SimplifySwift will not do or cut it for us
             */
//            //------------
//            // v2 (SimplifySwift)
//            // MARK: SimplifySwift simplify
//            let hQ: Bool = true
//            // MARK: Simplify (note this has simplification, v1 does not)
//            /// - Parameter tolerance: the higher the blocker and less points (default is 1)
//            /// - Returns: [CGPoints] Array
//            let simplifiedPoints = SwiftSimplify.simplify(self.coalescedPoints, tolerance: 1, highestQuality: hQ)
//            // MARK: Smoothen
//            let simplifiedPath: UIBezierPath = UIBezierPath.smoothFromPoints(simplifiedPoints)

        //--------------------------------------------------------------
        // MARK: - Linearly interpolate between extracted points (fill points between final points, if distance is greater than kBrushPixelStep)
        //--------------------------------------------------------------
        var newCount: Int = 0
        if interpolateBetweenPoints {

            var coalescedInterpolated: [SIMD2<Float>] = []
            
            for i in 0 ..< pointsFromPath.count-1 {
                
                // MARK: - get the pair of points to interpolate between
                let p0: SIMD2<Float> = pointsFromPath[i]
                let p1: SIMD2<Float> = pointsFromPath[i+1]
                
                // MARK: - How many point do we need to distribute between each pair of points to satisfy the option to get n xpixes between each point
                let spacingCount = max(Int(ceilf(sqrtf((p1[0] - p0[0]) * (p1[0] - p0[0]) +
                                                       (p1[1] - p0[1]) * (p1[1] - p0[1])) / kBrushPixelStep.f)), 1)
                
                //self.lastdistance = spacingCount
                
                // MARK: - calculate position shift between the two points and append to the array
                for n in 0 ..< spacingCount {
                    coalescedInterpolated.append(p0 + (p1 - p0) * (n.f / spacingCount.f))
                }
            }
            
            /// Get the count of the array for the final points
            newCount = coalescedInterpolated.count
            //debug
            print("newCount: \(newCount)")
            // MARK: - Create the mtlbuffer
            if newCount > 0 {
                self.vertBuffer = metalDevice.makeBuffer(bytes: &coalescedInterpolated, length: MemoryLayout<SIMD2<Float>>.stride * newCount, options: [])
            }
            
        } else {
            
            /// Get the count of the array for the final points
            newCount = pointsFromPath.count
            //debug
            print("newCount: \(newCount)")
            // MARK: - Create the mtlbuffer
            if newCount > 0 {
                self.vertBuffer = metalDevice.makeBuffer(bytes: &pointsFromPath, length: MemoryLayout<SIMD2<Float>>.stride * newCount, options: [])
            }
        }
        

        drawInNextDrawable(loadAction: .load) { encoder in

            // MARK: - Draw

            encoder.setRenderPipelineState(program[PROGRAM_POINT].pipelineState)
            
            /// Bind vertex buffers
            //encoder.setVertexBytes(vertexBuffer, length: _points.count * 2 * MemoryLayout<Float>.size, index: 0)
            encoder.setVertexBuffer(vertBuffer, offset: 0, index: 0)
            encoder.setVertexBuffer(program[PROGRAM_POINT].uniform[UNIFORM_MVP], offset: 0, index: 1)
            encoder.setVertexBuffer(program[PROGRAM_POINT].uniform[UNIFORM_POINT_SIZE], offset: 0, index: 2)
            encoder.setVertexBuffer(program[PROGRAM_POINT].uniform[UNIFORM_VERTEX_COLOR], offset: 0, index: 3)
            
            /// Bind fragment buffers
            encoder.setFragmentTexture(brushTexture.texture, index: 0)
            encoder.setFragmentSamplerState(brushTexture.sampler, index: 0)
            
            /// Set viewport
            encoder.setViewport(viewport)
            
            /// Drawcall
            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: newCount)
        }
    }
    
    // MARK: ref: code.tutsplus.com/tutorials/smooth-freehand-drawing-on-ios--mobile-13164
    // - Remark: as of now, calling this for every newly added point is slow compared to our scheme
    private func midPoint() {
            
        // MARK: - Allocate vertex array buffer for GPU
        var pointsFromPath: [SIMD2<Float>] = []
                
        //--------------------------------------------------------------
        // MARK: - Guard check the [CGPoint] array collected from touch
        //--------------------------------------------------------------
        guard self.ctr == 4 else { return }
        
        let strokePath: UIBezierPath? = UIBezierPath()
        
        //-----------------------------------------------------------------
        /// Move the endpoint to the middle of the line jointing the second control point of the firstBezier segment and the first control point of the second Bezier segment
        self.points[3] = CGPoint(x: (self.points[2].x + self.points[4].x)/2.0,
                                 y: (self.points[2].y + self.points[4].y)/2.0)
        
        strokePath?.move(to: self.points[0])
        /// add a cubic bezier from 0 to 3 with control points 1 and 2
        strokePath?.addCurve(to: self.points[3], controlPoint1: self.points[1], controlPoint2: self.points[2])
        
        /// replace points and get ready to handle the next segment
        self.points[0] = self.points[3]
        self.points[1] = self.points[4]
        
        self.ctr = 1
        //-----------------------------------------------------------------
        
        
        //--------------------------------------------------------------
        // MARK: - extract points from curve/spline
        //--------------------------------------------------------------
        if let strokePath = strokePath {
            pointsFromPath = self.extractPoints_fromUIBezierPath_f2(strokePath)!
        }
                
        //--------------------------------------------------------------
        // MARK: - Linearly interpolate between extracted points (fill points between final points, if distance is greater than kBrushPixelStep)
        //--------------------------------------------------------------
        var newCount: Int = 0
        if interpolateBetweenPoints {

            var coalescedInterpolated: [SIMD2<Float>] = []
                
            for i in 0 ..< pointsFromPath.count-1 {
                    
                // MARK: - get the pair of points to interpolate between
                let p0: SIMD2<Float> = pointsFromPath[i]
                let p1: SIMD2<Float> = pointsFromPath[i+1]
                    
                // MARK: - How many point do we need to distribute between each pair of points to satisfy the option to get n xpixes between each point
                let spacingCount = max(Int(ceilf(sqrtf((p1[0] - p0[0]) * (p1[0] - p0[0]) +
                                                       (p1[1] - p0[1]) * (p1[1] - p0[1])) / kBrushPixelStep.f)), 1)
                    
                //self.lastdistance = spacingCount
                    
                // MARK: - calculate position shift between the two points and append to the array
                for n in 0 ..< spacingCount {
                    coalescedInterpolated.append(p0 + (p1 - p0) * (n.f / spacingCount.f))
                }
            }
                
            /// Get the count of the array for the final points
            newCount = coalescedInterpolated.count
            //debug
            print("newCount: \(newCount)")
            // MARK: - Create the mtlbuffer
            if newCount > 0 {
                self.vertBuffer = metalDevice.makeBuffer(bytes: &coalescedInterpolated, length: MemoryLayout<SIMD2<Float>>.stride * newCount, options: [])
            }
                
        } else {
                
            /// Get the count of the array for the final points
            newCount = pointsFromPath.count
            //debug
            print("newCount: \(newCount)")
            // MARK: - Create the mtlbuffer
            if newCount > 0 {
                self.vertBuffer = metalDevice.makeBuffer(bytes: &pointsFromPath, length: MemoryLayout<SIMD2<Float>>.stride * newCount, options: [])
            }
        }
            
        drawInNextDrawable(loadAction: .load) { encoder in

            // MARK: - Draw

            encoder.setRenderPipelineState(program[PROGRAM_POINT].pipelineState)
                
            /// Bind vertex buffers
            //encoder.setVertexBytes(vertexBuffer, length: _points.count * 2 * MemoryLayout<Float>.size, index: 0)
            encoder.setVertexBuffer(vertBuffer, offset: 0, index: 0)
            encoder.setVertexBuffer(program[PROGRAM_POINT].uniform[UNIFORM_MVP], offset: 0, index: 1)
            encoder.setVertexBuffer(program[PROGRAM_POINT].uniform[UNIFORM_POINT_SIZE], offset: 0, index: 2)
            encoder.setVertexBuffer(program[PROGRAM_POINT].uniform[UNIFORM_VERTEX_COLOR], offset: 0, index: 3)
                
            /// Bind fragment buffers
            encoder.setFragmentTexture(brushTexture.texture, index: 0)
            encoder.setFragmentSamplerState(brushTexture.sampler, index: 0)
                
            /// Set viewport
            encoder.setViewport(viewport)
                
            /// Drawcall
            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: newCount)
        }
    }
    
    // MARK: - BEGAN
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if !self.midpointLine && self.useCoalescedTouches {
            points.removeAll(keepingCapacity: true)
        } else {
            self.points = Array(repeating: CGPoint(), count: 5)
        }
        
        let bounds = self.bounds
        
        self.ctr = 0
        
        if useCoalescedTouches {
            
            if let coalesced = event?.coalescedTouches(for: touches.first!) {
                
                for touch in coalesced {
                    // Convert touch point from UIView referential to OpenGL one (upside-down flip)
                    var location = touch.preciseLocation(in: self)
                    location.y = bounds.size.height - location.y
                    points.append(location)
                }
            }
            
        } else {
            if let touch: UITouch = touches.first {
                
                // Convert touch point from UIView referential to OpenGL one (upside-down flip)
                var location = touch.location(in: self)
                location.y = bounds.size.height - location.y
                
                 if !self.midpointLine {
                     points.append(location)
                 } else {
                    self.points[0] = location
                 }
            }
        }
    }
    
    // MARK: - MOVED
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
                    
        let bounds: CGRect = self.bounds
        
        if useCoalescedTouches {
        
            if let coalesced = event?.coalescedTouches(for: touches.first!) {
                
                for touch in coalesced {
                    
                    // Convert touch point from UIView referential to OpenGL one (upside-down flip)
                    var location = touch.preciseLocation(in: self)
                    location.y = bounds.size.height - location.y
                    points.append(location)
                }
            }
            
        } else {
            
            if let touch: UITouch = touches.first {
                // Convert touch point from UIView referential to OpenGL one (upside-down flip)
                var location = touch.location(in: self)
                location.y = bounds.size.height - location.y
                
                if !self.midpointLine {
                    points.append(location)
                                       
                } else {
                    self.ctr += 1
                    self.points[ctr] = location
                    self.midPoint()
                }
            }
        }
        
        // MARK: - Predicted touches
        if usePredictedTouches {
           if let coalesced = event?.predictedTouches(for: touches.first!) {
                for touch in coalesced {
                    // Convert touch point from UIView referential to OpenGL one (upside-down flip)
                    var location = touch.preciseLocation(in: self)
                    location.y = bounds.size.height - location.y
                    points.append(location)
                }
            }
        }

        if !self.midpointLine {
            // MARK: - Render the stroke
            self.renderLine(points: self.points)
        }
    }

    // MARK: - ENDED
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if !self.midpointLine {
            if let coalesced = event?.coalescedTouches(for: touches.first!) {
                
                for touch in coalesced {
                    
                    // Convert touch point from UIView referential to OpenGL one (upside-down flip)
                    var location = touch.preciseLocation(in: self)
                    location.y = bounds.size.height - location.y
                    points.append(location)
                    self.renderLine(points: self.points)
                }
            }
        } else {
            self.ctr = 0
        }
    }

    // MARK: - CANCELLED
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    
    // Erases the screen
    func erase() {
        drawInNextDrawable{_ in
            //Nothing more...
        }
    }
    func setBrushColor(red: CGFloat, green: CGFloat, blue: CGFloat) {
        
        // Update the brush color
        brushColor[0] = red.f * kBrushOpacity.f
        brushColor[1] = green.f * kBrushOpacity.f
        brushColor[2] = blue.f * kBrushOpacity.f
        brushColor[3] = kBrushOpacity.f

        if initialized {
            let uniformVertexColor = metalDevice.makeBuffer(bytes: brushColor, length: MemoryLayout<Float>.size * brushColor.count)
            program[PROGRAM_POINT].uniform[UNIFORM_VERTEX_COLOR] = uniformVertexColor
        }
    }
    private func createRenderTargetTexture(from texture: MTLTexture) -> MTLTexture {
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = MTLTextureType.type2D
        textureDescriptor.width = texture.width
        textureDescriptor.height = texture.height
        textureDescriptor.pixelFormat = texture.pixelFormat
        textureDescriptor.storageMode = .shared
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        
        let sampleTexture = metalDevice.makeTexture(descriptor: textureDescriptor)
        return sampleTexture!
    }
    override var canBecomeFirstResponder : Bool {
        return true
    }
}

// pi add
extension PaintingView {
    
    /// Getting the points from the bezier stroke, we put them into the buffer type we will use to send to the GPU
    private func extractPoints_fromUIBezierPath(_ bezPath: UIBezierPath?) -> [Float]? {
            
        if let bezPath: UIBezierPath = bezPath, !bezPath.isEmpty {
            return bezPath.cgPath.points_f!
        }
                
        return nil
    }
    
    private func extractPoints_fromUIBezierPath_f2(_ bezPath: UIBezierPath?) -> [SIMD2<Float>]? {
        
        if let bezPath: UIBezierPath = bezPath, !bezPath.isEmpty {
            return bezPath.cgPath.points_f2!
        }
        
       return nil
    }

}

