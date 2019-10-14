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

enum EInterpolationMethod: Int {
    
    /// The raw value is the number of points to check for before trimming
    case hermite = 1
    case catmullRom = 3
}

enum ESpliningType: Int {
    
    case thirdPartyCatmullRom
    case appleLine
    case appleQuad
    case appleCurve
    case SadunSmoothing
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
    var coalescedPoints: [CGPoint] = []
    var predictedPoints: [CGPoint] = []
    
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
    let kBrushScale = 3.0
    
    // MARK: - CONSTANTS:
    private var useCoalescedTouches: Bool = true // :false
    private var usePredictedTouches: Bool = false // :false
    private var interpolation: EInterpolationMethod = .catmullRom // :.catmullRom // .hermite is still buggy and jittery, not sure why
    private var interpolateBetweenPoints: Bool = true // :true
    /// - Remark: :false, works
    /// - Remark: :true, possibly buggy, causes jittery strokes, not sure if the splining itself is faulty or other parts in the strokes handling algo causes the problems
    private var splinePoints: Bool = false // :false
    private var eSpliningType: ESpliningType = .SadunSmoothing
    
    // MARK: - Draws a line onscreen based on where the user touches
    private func renderLine(points: [CGPoint],
                            coalescedPoints: [CGPoint],
                            predictedPoints: [CGPoint]) {
        
        // MARK: - Allocate vertex array buffer for GPU
        var pointsFromPath: [SIMD2<Float>] = []

        switch (self.interpolation)
        {
        case .catmullRom:
            
            //--------------------------------------------------------------
            // MARK: - Guard check the [CGPoint] array collected from touch
            //--------------------------------------------------------------
            switch (self.eSpliningType) {
                
            case .appleLine:
                guard self.coalescedPoints.count > 1 else { return }
                
            case .appleQuad:
                guard self.coalescedPoints.count > 2 else { return }
                
            case .thirdPartyCatmullRom, .appleCurve, .SadunSmoothing:
                guard self.coalescedPoints.count > 3 else { return }
                
            @unknown default:
                break
            }
            
            //--------------------------------------------------------------
            // MARK: Spline/Bezier/Smoothen the collected [CGPoint] array
            //--------------------------------------------------------------
            // local copy the global points
            let touchPoints = self.coalescedPoints

            if splinePoints {
                
                var strokePath: UIBezierPath? = UIBezierPath()

                switch (self.eSpliningType) {
                    
                case .thirdPartyCatmullRom:
                    
                    strokePath = INTERP.interpolateCGPointsWithCatmullRom(
                        pointsAsNSValues: touchPoints,
                        closed: false,
                        alpha: 0.5)
                    
                case .appleLine:
                    
                    if touchPoints.count >= 2 {
                        for i in 0 ..< touchPoints.count - 1 {
                            strokePath?.move(to: touchPoints[i]) // start point
                            strokePath?.addLine(to: touchPoints[i+1]) // end point
                        }
                    }
                    
                case .appleQuad:
                    
                    if touchPoints.count >= 3 {
                        for i in 0 ..< touchPoints.count - 3 {
                                               
                            //if (touchPoints[i] - touchPoints[i+3]).quadrance > 0.003 {
                                strokePath?.move(to: touchPoints[i]) // start point
                                strokePath?.addQuadCurve(to: touchPoints[i+2], controlPoint: touchPoints[i+1])
                            //}
                        }
                    }
                    
                case .appleCurve:
         
                    if touchPoints.count >= 4 {
                        for i in 0 ..< touchPoints.count - 3 {
                            
                            //if (touchPoints[i] - touchPoints[i+3]).quadrance > 0.003 {
                            
                                strokePath?.move(to: touchPoints[i]) // start point
                                strokePath?.addCurve(to: touchPoints[i+3], // end point
                                                        controlPoint1: touchPoints[i+1], // control point for start point
                                                        controlPoint2: touchPoints[i+2]) // control point for end point
                            //}
                        }
                    }
                    
                case .SadunSmoothing:
                    
                    for i in 0 ..< touchPoints.count-1 {
                        strokePath?.move(to: touchPoints[i]) // start point
                        strokePath?.addLine(to: touchPoints[i+1])
                    }
 
                    // MARK: - Spline/Bezier/Smoothen the collected [CGPoint] array (Erica Sadun's version)
                    if smoothCurve {
                        /// smoothen
                        strokePath?.smoothened(granularity: 1) // smoothen test
                    }
                }

                //--------------------------------------------------------------
                // MARK: - extract points from curve/spline
                //--------------------------------------------------------------
                if let strokePath = strokePath {
                   pointsFromPath = self.extractPoints_fromUIBezierPath_f2(strokePath)!
                }
                
                
            } else {
                pointsFromPath = self.coalescedPoints.map { $0.f2 * 2.0 }
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
            // MARK: - trim
            //--------------------------------------------------------------
            if self.useCoalescedTouches {
                
                if self.useCoalescedTouches {

                    if !self.coalescedPoints.isEmpty {
                        let lastPoint = self.coalescedPoints.last!
                        // remake the array using the last point
                        self.coalescedPoints = [lastPoint]
                    }

                } else {
                    if self.coalescedPoints.count > self.interpolation.rawValue {
                        self.coalescedPoints.removeFirst(self.interpolation.rawValue)
                    }
                }

//                if splinePoints {
//                    if self.coalescedPoints.count > self.interpolation.rawValue {
//                        // ... Store 4 last points
//                        let p0 = self.coalescedPoints[self.coalescedPoints.count-4]
//                        let p1 = self.coalescedPoints[self.coalescedPoints.count-3]
//                        let p2 = self.coalescedPoints[self.coalescedPoints.count-2]
//                        let p3 = self.coalescedPoints[self.coalescedPoints.count-1] // last point
//
//                        // remake the array using the last 4 points
//                        self.coalescedPoints = [/*p0, p1, p2,*/ p3]
//
//                        print("left: \(self.coalescedPoints.count)")
//                    }
//
//                } else {
//                    if interpolateBetweenPoints {
//                        let lastPoint = self.coalescedPoints.last!
//                        // remake the array using the last 4 points
//                        self.coalescedPoints = [lastPoint]
//
//                    } else {
//                       self.coalescedPoints.removeAll() // This fixes the overlapping points, but how to interpolate properly?, but produces gaps if interpolating
//                    }
//                }
                
            } else {
                if self.coalescedPoints.count > self.interpolation.rawValue {
                    self.coalescedPoints.removeFirst(self.interpolation.rawValue) // .removeFirst(3) worked! with splining and interpolate between points
                }
            }
            
        case .hermite:
        
            //--------------------------------------------------------------
            // MARK: - Guard check the [CGPoint] array collected from touch
            //--------------------------------------------------------------
            guard coalescedPoints.count > self.interpolation.rawValue else { return }
            
            //--------------------------------------------------------------
            // MARK: Spline/Bezier/Smoothen the collected [CGPoint] array
            //--------------------------------------------------------------
            // local copy the global points
            let simplifiedPoints = self.coalescedPoints
            
            guard let simplifiedPath = INTERP.interpolateCGPointsWithHermite(pointsAsNSValues: simplifiedPoints, closed: false) else {
                return ()
            }
            
            //--------------------------------------------------------------
            // MARK: - extract points from curve/spline
            //--------------------------------------------------------------
            pointsFromPath = self.extractPoints_fromUIBezierPath_f2(simplifiedPath)!
            
            //--------------------------------------------------------------
            // MARK: - trim
            //--------------------------------------------------------------
            if self.useCoalescedTouches {
                
                if !self.coalescedPoints.isEmpty {
                    let lastPoint = self.coalescedPoints.last!
                    // remake the array using the last point
                    self.coalescedPoints = [lastPoint]
                }
                
            } else {
                if self.coalescedPoints.count > self.interpolation.rawValue {
                    self.coalescedPoints.removeFirst(self.interpolation.rawValue)
                }
            }
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
        
        coalescedPoints.removeAll(keepingCapacity: true)
        let bounds = self.bounds
        
        if useCoalescedTouches {
            
            if let coalesced = event?.coalescedTouches(for: touches.first!) {
                for touch in coalesced {
                    // Convert touch point from UIView referential to OpenGL one (upside-down flip)
                    var location = touch.preciseLocation(in: self)
                    location.y = bounds.size.height - location.y
                    coalescedPoints.append(location)
                }
            }
            
        } else {
            if let touch: UITouch = touches.first {
                // Convert touch point from UIView referential to OpenGL one (upside-down flip)
                var location = touch.location(in: self)
                location.y = bounds.size.height - location.y
                coalescedPoints.append(location)
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
                    coalescedPoints.append(location)
                }
            }
            
        } else {
            if let touch: UITouch = touches.first {
                // Convert touch point from UIView referential to OpenGL one (upside-down flip)
                var location = touch.location(in: self)
                location.y = bounds.size.height - location.y
                coalescedPoints.append(location)
            }
        }
        
        // MARK: - Predicted touches
        if usePredictedTouches {
           if let coalesced = event?.predictedTouches(for: touches.first!) {
                for touch in coalesced {
                    // Convert touch point from UIView referential to OpenGL one (upside-down flip)
                    var location = touch.preciseLocation(in: self)
                    location.y = bounds.size.height - location.y
                    coalescedPoints.append(location)
                }
            }
        }

        // MARK: - Render the stroke
        self.renderLine(points: self.points,
                        coalescedPoints: self.coalescedPoints,
                        predictedPoints: self.predictedPoints)
    }

    // MARK: - ENDED
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let coalesced = event?.coalescedTouches(for: touches.first!) {
            
            for touch in coalesced {
                
                // Convert touch point from UIView referential to OpenGL one (upside-down flip)
                var location = touch.preciseLocation(in: self)
                location.y = bounds.size.height - location.y
                coalescedPoints.append(location)
            }
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

