//
//  CTPanoramaView.swift
//  TestingCTPano
//
//  Created by Jack Wong on 1/21/20.
//  Copyright © 2020 Jack Wong. All rights reserved.
//

import UIKit
import SceneKit
import CoreMotion
import ImageIO


@objc public protocol CTPanoramaCompass {
    func updateUI(rotationAngle: CGFloat, fieldOfViewAngle: CGFloat)
}

@objc public enum CTPanoramaControlMethod: Int {
    case motion
    case touch
}

@objc public class CTPanoramaView: UIView {
    
    var imageDictionary = [String: UIImage]()
    
    
    // MARK: Public properties
    //    public var pursuitGraph = Graph()
    
    @objc public var compass: CTPanoramaCompass?
    @objc public var movementHandler: ((_ rotationAngle: CGFloat, _ fieldOfViewAngle: CGFloat) -> Void)?
    @objc public var panSpeed = CGPoint(x: 0.005, y: 0.005)
    @objc public var startAngle: Float = 0
    
    
    @objc public var overlayView: UIView? {
        didSet {
            replace(overlayView: oldValue, with: overlayView)
        }
    }
    
    @objc public var controlMethod: CTPanoramaControlMethod = .touch {
        didSet {
            switchControlMethod(to: controlMethod)
            resetCameraAngles()
        }
    }
    
    // MARK: Private properties
    private var pursuitGraph = Graph()
    
    private let radius: CGFloat = 10
    public let sceneView = SCNView()
    private let scene = SCNScene()
    private let motionManager = CMMotionManager()
    private var geometryNode: SCNNode?
    private var prevLocation = CGPoint.zero
    private var prevBounds = CGRect.zero
    
    private lazy var cameraNode: SCNNode = {
        let node = SCNNode()
        let camera = SCNCamera()
        node.camera = camera
        return node
    }()
    
    private lazy var opQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInteractive
        return queue
    }()
    
    private lazy var fovHeight: CGFloat = {
        return tan(self.yFov/2 * .pi / 180.0) * 2 * self.radius
    }()
    
    private var startScale = 0.0
    
    private var xFov: CGFloat {
        return yFov * self.bounds.width / self.bounds.height
    }
    
    private var yFov: CGFloat {
        get {
            if #available(iOS 11.0, *) {
                return cameraNode.camera?.fieldOfView ?? 0
            } else {
                return CGFloat(cameraNode.camera?.yFov ?? 0)
            }
        }
        set {
            if #available(iOS 11.0, *) {
                cameraNode.camera?.fieldOfView = newValue
            } else {
                cameraNode.camera?.yFov = Double(newValue)
            }
        }
    }
    
    
    // MARK: Class lifecycle methods
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public convenience init(frame: CGRect, image: UIImage) {
        self.init(frame: frame)
        // Force Swift to call the property observer by calling the setter from a non-init context
        commonInit()
    }
    
    deinit {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }
    
    private func commonInit() {
        
        pursuitGraph =  GraphData.manager.populateGraph()
        
        for room in pursuitGraph.floorPlan{
            guard let image = room.imageURL else {continue}
            
            if var newRoom = UIImage(named: image){
                newRoom = newRoom.resize(image: newRoom)
                imageDictionary[image] = newRoom
            }
        }
        
        
        add(view: sceneView)
        
        scene.rootNode.addChildNode(cameraNode)
        yFov = 80
        resetCameraAngles()
        sceneView.scene = scene
        sceneView.backgroundColor = UIColor.black
        
        switchControlMethod(to: controlMethod)
        
        guard let firstRoom = pursuitGraph.floorPlan.first else { return }
        
        //Creating the node based on the first element of the floorplan
        createGeometryNode(imageURL: firstRoom.imageURL)
        
        for hotspot in firstRoom.hotspots {
            
            if let name = hotspot.neighbor.name{
                
                createHotSpotNode(name: name, position: SCNVector3Make(hotspot.coordinates.0, hotspot.coordinates.1, hotspot.coordinates.2))
            }
            
        }
    }
    
    // MARK: Configuration helper methods
    
//    private func createGeometryNode(imageURL: String?) {
//
//        guard let image = imageURL else { return }
//
//        guard let selectedImage = UIImage(named: image) else {return}
//
//        if geometryNode != nil{
//            geometryNode?.removeFromParentNode()
//        }
//
//        let material = SCNMaterial()
//        material.diffuse.contents = selectedImage.resize(image: selectedImage)
//        material.diffuse.mipFilter = .nearest
//        material.diffuse.magnificationFilter = .nearest
//        material.diffuse.contentsTransform = SCNMatrix4MakeScale(-1, 1, 1)
//        material.diffuse.wrapS = .repeat
//        material.cullMode = .front
//
//        let sphere = SCNSphere(radius: radius)
//        sphere.segmentCount = 300
//
//        sphere.firstMaterial = material
//
//        let sphereNode = SCNNode()
//        sphereNode.geometry = sphere
//
//        //Rotating the sphere 180 degrees so that the camera node will face the the center of the photosphere.
//        sphereNode.rotation = SCNVector4Make(0, 1, 0, Float(180).toRadians())
//        geometryNode = sphereNode
//
//        guard let photoSphereNode = geometryNode else {return}
//        scene.rootNode.addChildNode(photoSphereNode)
//        resetCameraAngles()
//    }
    
    private func createGeometryNode(imageURL: String?) {
        
        guard let image = imageURL else { return }
                
        if geometryNode != nil{
            geometryNode?.removeFromParentNode()
        }
        
        let material = SCNMaterial()
        material.diffuse.contents = imageDictionary[image]!
//        material.diffuse.contents = selectedImage.resize(image: selectedImage)
        material.diffuse.mipFilter = .nearest
        material.diffuse.magnificationFilter = .nearest
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(-1, 1, 1)
        material.diffuse.wrapS = .repeat
        material.cullMode = .front
        
        let sphere = SCNSphere(radius: radius)
        sphere.segmentCount = 300
        
        sphere.firstMaterial = material
        
        let sphereNode = SCNNode()
        sphereNode.geometry = sphere
        
        //Rotating the sphere 180 degrees so that the camera node will face the the center of the photosphere.
        sphereNode.rotation = SCNVector4Make(0, 1, 0, Float(180).toRadians())
        geometryNode = sphereNode
        
        guard let photoSphereNode = geometryNode else {return}
        scene.rootNode.addChildNode(photoSphereNode)
        resetCameraAngles()
    }
    
    private func createHotSpotNode(name: String, position: SCNVector3){
        let sphere = SCNSphere(radius: 0.5)
        sphere.firstMaterial = SCNMaterial(color: .clear)
        let newHotSpotNode = SCNNode()
        newHotSpotNode.geometry = sphere
        newHotSpotNode.position = position
        newHotSpotNode.name = name

        let colorSphere = SCNSphere(radius: 0.2)
        colorSphere.firstMaterial?.diffuse.contents = UIColor.green

        let colorNode = SCNNode()
        colorNode.geometry = colorSphere
        colorNode.position = position
        colorNode.name = name
        
        geometryNode?.addChildNode(newHotSpotNode)
        geometryNode?.addChildNode(colorNode)
    }
    
    private func replace(overlayView: UIView?, with newOverlayView: UIView?) {
        overlayView?.removeFromSuperview()
        guard let newOverlayView = newOverlayView else {return}
        add(view: newOverlayView)
    }
    
    private func switchControlMethod(to method: CTPanoramaControlMethod) {
        sceneView.gestureRecognizers?.removeAll()
        
        if method == .touch {
            let panGestureRec = UIPanGestureRecognizer(target: self, action: #selector(handlePan(panRec:)))
            sceneView.addGestureRecognizer(panGestureRec)
            
            let pinchRec = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(pinchRec:)))
            sceneView.addGestureRecognizer(pinchRec)
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            sceneView.addGestureRecognizer(tapGesture)
            
            if motionManager.isDeviceMotionActive {
                motionManager.stopDeviceMotionUpdates()
            }
        } else {
            guard motionManager.isDeviceMotionAvailable else {return}
            
            //Resetting the field of view
            yFov = 80
            
            motionManager.deviceMotionUpdateInterval = 0.015
            motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: opQueue,
                                                   withHandler: { [weak self] (motionData, error) in
                                                    guard let panoramaView = self else {return}
                                                    guard panoramaView.controlMethod == .motion else {return}
                                                    
                                                    guard let motionData = motionData else {
                                                        print("\(String(describing: error?.localizedDescription))")
                                                        panoramaView.motionManager.stopDeviceMotionUpdates()
                                                        return
                                                    }
                                                    
                                                    let rotationMatrix = motionData.attitude.rotationMatrix
                                                    var userHeading = .pi - atan2(rotationMatrix.m32, rotationMatrix.m31)
                                                    userHeading += .pi/2
                                                    
                                                    DispatchQueue.main.async {
                                                        // Use quaternions when in spherical mode to prevent gimbal lock
                                                        panoramaView.cameraNode.orientation = motionData.orientation()
                                                        
                                                        panoramaView.reportMovement(CGFloat(userHeading), panoramaView.xFov.toRadians())
                                                    }
            })
        }
    }
    
    
    private func resetCameraAngles() {
        cameraNode.eulerAngles = SCNVector3Make(0, startAngle, 0)
        self.reportMovement(CGFloat(startAngle), xFov.toRadians(), callHandler: false)
    }
    
    private func reportMovement(_ rotationAngle: CGFloat, _ fieldOfViewAngle: CGFloat, callHandler: Bool = true) {
        compass?.updateUI(rotationAngle: rotationAngle, fieldOfViewAngle: fieldOfViewAngle)
        if callHandler {
            movementHandler?(rotationAngle, fieldOfViewAngle)
        }
    }
    
    // MARK: Gesture handling
    
    @objc private func handlePan(panRec: UIPanGestureRecognizer) {
        if panRec.state == .began {
            prevLocation = CGPoint.zero
        } else if panRec.state == .changed {
            //            var modifiedPanSpeed = panSpeed
            let modifiedPanSpeed = panSpeed
            
            let location = panRec.translation(in: sceneView)
            let orientation = cameraNode.eulerAngles
            var newOrientation = SCNVector3Make(orientation.x + Float(location.y - prevLocation.y) * Float(modifiedPanSpeed.y),
                                                orientation.y + Float(location.x - prevLocation.x) * Float(modifiedPanSpeed.x),
                                                orientation.z)
            
            if controlMethod == .touch {
                newOrientation.x = max(min(newOrientation.x, 1.1), -1.1)
            }
            
            cameraNode.eulerAngles = newOrientation
            prevLocation = location
            
            reportMovement(CGFloat(-cameraNode.eulerAngles.y), xFov.toRadians())
        }
    }
    
    @objc func handlePinch(pinchRec: UIPinchGestureRecognizer) {
        if pinchRec.numberOfTouches != 2 {
            return
        }
        
        let zoom = Double(pinchRec.scale)
        switch pinchRec.state {
        case .began:
            startScale = cameraNode.camera!.yFov
        case .changed:
            let fov = startScale / zoom
            if fov > 20 && fov < 80 {
                cameraNode.camera!.yFov = fov
            }
        default:
            break
        }
    }
    //MARK:-- Tap Method.  If a hotspot node is tapped the next room should appear
    @objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        if gestureRecognize.state == .ended{
            
            let scnView = sceneView
            
            //MARK:- Check what nodes are tapped
            let touchLocation = gestureRecognize.location(in: scnView)
            let hitResults = scnView.hitTest(touchLocation, options: nil)
            //MARK:- Show tapped coordinates
            if hitResults.count > 0 {
                // retrieved the first clicked object
                let result: SCNHitTestResult = hitResults[0]
                let vect:SCNVector3 = result.localCoordinates
                print(vect)
            }
            if let result = hitResults.first {
                
                guard let nodeName = result.node.name else {
                    print("You tapped on nothing")
                    return
                }
                
                self.makeToast("You entered \(nodeName)")
                
                let something = pursuitGraph.floorPlan.filter { $0.name == nodeName}
                
                //Resetting the field of view
                yFov = 80
                
                //Creating all the selected room's hotspots
                for i in something{
                    
                    createGeometryNode(imageURL: i.imageURL)
                    
                    for hotspot in i.hotspots{
                        if let name = hotspot.neighbor.name{
                            createHotSpotNode(name: name, position: SCNVector3Make(hotspot.coordinates.0, hotspot.coordinates.1, hotspot.coordinates.2))
                        }
                    }
                }
            }
        }
    }
    
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size.width != prevBounds.size.width || bounds.size.height != prevBounds.size.height {
            sceneView.setNeedsDisplay()
            reportMovement(CGFloat(-cameraNode.eulerAngles.y), xFov.toRadians(), callHandler: false)
        }
    }
}

private extension CMDeviceMotion {
    
    func orientation() -> SCNVector4 {
        
        let attitude = self.attitude.quaternion
        let attitudeQuanternion = GLKQuaternion(quanternion: attitude)
        
        let result: SCNVector4
        
        switch UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation {
            
        case .landscapeRight:
            let cq1 = GLKQuaternionMakeWithAngleAndAxis(.pi/2, 0, 1, 0)
            let cq2 = GLKQuaternionMakeWithAngleAndAxis(-(.pi/2), 1, 0, 0)
            var quanternionMultiplier = GLKQuaternionMultiply(cq1, attitudeQuanternion)
            quanternionMultiplier = GLKQuaternionMultiply(cq2, quanternionMultiplier)
            
            result = quanternionMultiplier.vector(for: .landscapeRight)
            
        case .landscapeLeft:
            let cq1 = GLKQuaternionMakeWithAngleAndAxis(-(.pi/2), 0, 1, 0)
            let cq2 = GLKQuaternionMakeWithAngleAndAxis(-(.pi/2), 1, 0, 0)
            var quanternionMultiplier = GLKQuaternionMultiply(cq1, attitudeQuanternion)
            quanternionMultiplier = GLKQuaternionMultiply(cq2, quanternionMultiplier)
            
            result = quanternionMultiplier.vector(for: .landscapeLeft)
            
        case .portraitUpsideDown:
            let cq1 = GLKQuaternionMakeWithAngleAndAxis(-(.pi/2), 1, 0, 0)
            let cq2 = GLKQuaternionMakeWithAngleAndAxis(.pi, 0, 0, 1)
            var quanternionMultiplier = GLKQuaternionMultiply(cq1, attitudeQuanternion)
            quanternionMultiplier = GLKQuaternionMultiply(cq2, quanternionMultiplier)
            
            result = quanternionMultiplier.vector(for: .portraitUpsideDown)
            
        default:
            let clockwiseQuanternion = GLKQuaternionMakeWithAngleAndAxis(-(.pi/2), 1, 0, 0)
            let quanternionMultiplier = GLKQuaternionMultiply(clockwiseQuanternion, attitudeQuanternion)
            
            result = quanternionMultiplier.vector(for: .portrait)
        }
        return result
    }
}

private extension UIView {
    func add(view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        let views = ["view": view]
        let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "|[view]|", options: [], metrics: nil, views: views)    //swiftlint:disable:this line_length
        let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: views)  //swiftlint:disable:this line_length
        self.addConstraints(hConstraints)
        self.addConstraints(vConstraints)
    }
}

private extension FloatingPoint {
    func toDegrees() -> Self {
        return self * 180 / .pi
    }
    
    func toRadians() -> Self {
        return self * .pi / 180
    }
}

private extension GLKQuaternion {
    init(quanternion: CMQuaternion) {
        self.init(q: (Float(quanternion.x), Float(quanternion.y), Float(quanternion.z), Float(quanternion.w)))
    }
    
    func vector(for orientation: UIInterfaceOrientation) -> SCNVector4 {
        switch orientation {
        case .landscapeRight:
            return SCNVector4(x: -self.y, y: self.x, z: self.z, w: self.w)
            
        case .landscapeLeft:
            return SCNVector4(x: self.y, y: -self.x, z: self.z, w: self.w)
            
        case .portraitUpsideDown:
            return SCNVector4(x: -self.x, y: -self.y, z: self.z, w: self.w)
            
        default:
            return SCNVector4(x: self.x, y: self.y, z: self.z, w: self.w)
        }
    }
}
