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

// MARK: - CONSTANTS:

let kBrushOpacity = (1.0 / 3.0)
let kBrushPixelStep = 3
let kBrushScale = 2


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


// Texture

struct TextureInfo {
    var texture: MTLTexture?
    var sampler: MTLSamplerState?
    
    init() {
        texture = nil
        sampler = nil
    }
}


class PaintingView: UIView {
    
    // The pixel dimensions of the backbuffer

    private var backingWidth: Int = 0
    private var backingHeight: Int = 0

    private var metalDevice: MTLDevice
    private var metalCommandQueue: MTLCommandQueue

    private var renderTargetTexture: MTLTexture!

    private var brushTexture: TextureInfo! // brush texture
    private var brushColor: [Float] = [0, 0, 0, 0] // brush color

    private var firstTouch: Bool = false
    private var needsErase: Bool = false

    // Viewport
    private var viewport: MTLViewport!

    private var initialized: Bool = false

    var location: CGPoint = CGPoint()
    var previousLocation: CGPoint = CGPoint()
    
    var points: [CGPoint] = []
    var vertBuffer: MTLBuffer? = nil

    // Implement this to override the default layer class (which is [CALayer class]).
    // We do this so that our view will be backed by a layer that is capable of OpenGL ES rendering.
    override class var layerClass : AnyClass {
        return CAMetalLayer.self
    }

    // The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
    required init?(coder: NSCoder) {
        guard
            let metalDevice = MTLCreateSystemDefaultDevice(),
            let metalCommandQueue = metalDevice.makeCommandQueue()
        else {
            fatalError("Metal is unavalable")
        }
        self.metalDevice = metalDevice
        self.metalCommandQueue = metalCommandQueue

        super.init(coder: coder)
        //let eaglLayer = self.layer as! CAEAGLLayer
        let metalLayer = self.layer as! CAMetalLayer
        metalLayer.framebufferOnly = false

        //eaglLayer.isOpaque = true
        metalLayer.isOpaque = true
        
        //### No simple ways to simulate `kEAGLDrawablePropertyRetainedBacking: true`
        //### See codes marked as [kEAGLDrawablePropertyRetainedBacking]
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

            program[i].pipelineState = try! metalDevice
                .makeRenderPipelineState(descriptor: pipelineStateDescriptor)

            // Set constant/initalize uniforms
            if i == PROGRAM_POINT {

                // viewing matrices
                print(backingWidth, backingHeight)
                let projectionMatrix = float4x4.orthoLeftHand(0, backingWidth.f, 0, backingHeight.f, -1, 1)
                let modelViewMatrix = float4x4.identity
                var MVPMatrix = projectionMatrix * modelViewMatrix

                let uniformMVP = metalDevice.makeBuffer(bytes: &MVPMatrix, length: MemoryLayout<float4x4>.size)
                
                // point size
                var pointSize = (brushTexture.texture?.width.f ?? 0) / kBrushScale.f
                let uniformPointSize = metalDevice.makeBuffer(bytes: &pointSize, length: MemoryLayout<Float>.size)

                // initialize brush color
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

        // Playback recorded path, which is "Shake Me"
        let recordedPaths = NSArray(contentsOfFile: Bundle.main.path(forResource: "Recording", ofType: "data")!)! as! [Data]
        if recordedPaths.count != 0 {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 200 * NSEC_PER_MSEC.d / NSEC_PER_SEC.d) {
                self.playback(recordedPaths, fromIndex: 0)
            }
        }

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

        guard let commandBuffer = metalCommandQueue.makeCommandBuffer() else {
            return
        }
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                return
        }

        drawing(renderEncoder)
        
        renderEncoder.endEncoding()
        
        // MARK: - Display the buffer
        //### Copy render target to drawable
        let blit = commandBuffer.makeBlitCommandEncoder()!
        let sourceSize = MTLSize(width: drawable.texture.width, height: drawable.texture.height, depth: 1)
        blit.copy(from: renderTargetTexture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0), sourceSize: sourceSize, to: drawable.texture, destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        blit.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    // Erases the screen
    func erase() {
        drawInNextDrawable{_ in
            //Nothing more...
        }
    }

    // Drawings a line onscreen based on where the user touches
    private func renderLine(from _start: CGPoint, to _end: CGPoint) {

        // MARK: - Convert locations from Points to Pixels
        let scale: CGFloat = self.contentScaleFactor
        var start: CGPoint = _start
        start.x *= scale
        start.y *= scale
        var end: CGPoint = _end
        end.x *= scale
        end.y *= scale

        // MARK: - Allocate vertex array buffer
        var vertexBuffer: [Float] = []

        // MARK: - Add points to the buffer so there are drawing points every X pixels
        let count = max(Int(ceilf(sqrtf((end.x - start.x).f * (end.x - start.x).f + (end.y - start.y).f * (end.y - start.y).f) / kBrushPixelStep.f)), 1)

        vertexBuffer.reserveCapacity(count * 2)

        for i in 0 ..< count {

            vertexBuffer.append(start.x.f + (end.x - start.x).f * (i.f / count.f))
            vertexBuffer.append(start.y.f + (end.y - start.y).f * (i.f / count.f))
        }

        drawInNextDrawable(loadAction: .load) {encoder in

            // MARK: - Draw

            encoder.setRenderPipelineState(program[PROGRAM_POINT].pipelineState)
            
            /// Bind vertex buffers
            encoder.setVertexBytes(vertexBuffer, length: count * 2 * MemoryLayout<Float>.size, index: 0)
            encoder.setVertexBuffer(program[PROGRAM_POINT].uniform[UNIFORM_MVP], offset: 0, index: 1)
            encoder.setVertexBuffer(program[PROGRAM_POINT].uniform[UNIFORM_POINT_SIZE], offset: 0, index: 2)
            encoder.setVertexBuffer(program[PROGRAM_POINT].uniform[UNIFORM_VERTEX_COLOR], offset: 0, index: 3)
            
            /// Bind fragment buffers
            encoder.setFragmentTexture(brushTexture.texture, index: 0)
            encoder.setFragmentSamplerState(brushTexture.sampler, index: 0)
            
            /// Set viewport
            encoder.setViewport(viewport)
            
            /// Drawcall
            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: count)
        }
    }

    private func renderLine(points: [CGPoint]) {
        
         var _points = points

        for i in 0 ..< points.count {
            
            _points[i].x = points[i].x * self.contentScaleFactor
            _points[i].y = points[i].y * self.contentScaleFactor
        }

        // MARK: - Allocate vertex array buffer
        var vertexBuffer: [Float] = []

       
        vertexBuffer.reserveCapacity(_points.count * 2)

        for i in 0 ..< _points.count {

            vertexBuffer.append(_points[i].x.f)
            vertexBuffer.append(_points[i].y.f)
        }
        
        vertBuffer = metalDevice.makeBuffer(bytes: &vertexBuffer, length: MemoryLayout<Float>.stride * _points.count * 2, options: [])

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
            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: _points.count)
        }
    }
    
    // Reads previously recorded points and draws them onscreen. This is the Shake Me message that appears when the application launches.

    private func playback(_ recordedPaths: [Data], fromIndex index: Int) {
        // NOTE: Recording.data is stored with 32-bit floats
        // To make it work on both 32-bit and 64-bit devices, we make sure we read back 32 bits each time.

        let data = recordedPaths[index]
        let count = data.count / (MemoryLayout<Float32>.size * 2) // each point contains 64 bits (32-bit x and 32-bit y)

        // Render the current path
        data.withUnsafeBytes { bytes in
            let floats = bytes.bindMemory(to: Float32.self).baseAddress!
            for i in 0 ..< count - 1 {

                var x = floats[2*i]
                var y = floats[2*i+1]
                let point1 = CGPoint(x: x.g, y: y.g)

                x = floats[2*(i+1)]
                y = floats[2*(i+1)+1]
                let point2 = CGPoint(x: x.g, y: y.g)

                self.renderLine(from: point1, to: point2)
            }
        }

        // Render the next path after a short delay
        if recordedPaths.count > index+1 {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 10 * NSEC_PER_MSEC.d / NSEC_PER_SEC.d) {
                self.playback(recordedPaths, fromIndex: index+1)
            }
        }
    }


    // Handles the start of a touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        points.removeAll(keepingCapacity: true)
        
        let bounds = self.bounds
        let touch = event!.touches(for: self)!.first!
        firstTouch = true
        // Convert touch point from UIView referential to OpenGL one (upside-down flip)
        location = touch.location(in: self)
        location.y = bounds.size.height - location.y
        
        points.append(location)
    }

    // Handles the continuation of a touch.
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let bounds = self.bounds
//        let touch = event!.touches(for: self)!.first!
        
        guard let touch: UITouch = touches.first,
              let event: UIEvent = event,
              let coalescedTouches: [UITouch] = event.coalescedTouches(for: touch),
              let predictedTouches: [UITouch] = event.predictedTouches(for: touch) else {
                
            return ()
        }
        
        //debug
        print(coalescedTouches.count)
        
        for touch in coalescedTouches {

            // Convert touch point from UIView referential to OpenGL one (upside-down flip)
            if firstTouch {
                firstTouch = false
                previousLocation = touch.previousLocation(in: self)
                previousLocation.y = bounds.size.height - previousLocation.y
                
                points.append(previousLocation)
                
            } else {
                location = touch.location(in: self)
                location.y = bounds.size.height - location.y
                previousLocation = touch.previousLocation(in: self)
                previousLocation.y = bounds.size.height - previousLocation.y
                
                points.append(location)
            }
        }
        
        for touch in predictedTouches {

            // Convert touch point from UIView referential to OpenGL one (upside-down flip)
            if firstTouch {
                firstTouch = false
                previousLocation = touch.previousLocation(in: self)
                previousLocation.y = bounds.size.height - previousLocation.y
                
                points.append(previousLocation)
                
            } else {
                location = touch.location(in: self)
                location.y = bounds.size.height - location.y
                previousLocation = touch.previousLocation(in: self)
                previousLocation.y = bounds.size.height - previousLocation.y
                
                points.append(location)
            }
        }
        
        // Render the stroke
        //self.renderLine(from: previousLocation, to: location)
        self.renderLine(points: points)
    }

    // Handles the end of a touch event when the touch is a tap.
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
//        let bounds = self.bounds
//        let touch = event!.touches(for: self)!.first!
//        if firstTouch {
//            firstTouch = false
//            previousLocation = touch.previousLocation(in: self)
//            previousLocation.y = bounds.size.height - previousLocation.y
//            self.renderLine(from: previousLocation, to: location)
//        }
        points.removeAll(keepingCapacity: true)
    }

    // Handles the end of a touch event.
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // If appropriate, add code necessary to save the state of the application.
        // This application is not saving state.
        points.removeAll(keepingCapacity: true)
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


    override var canBecomeFirstResponder : Bool {
        return true
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
}
