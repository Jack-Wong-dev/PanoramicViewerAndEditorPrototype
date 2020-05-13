//  Created by Jack Wong on 1/21/20.
//  Copyright © 2020 Jack Wong. All rights reserved.
//

import UIKit
import SceneKit
import CoreMotion
import ImageIO

@objc public enum HUD: Int {
    case show
    case hide
}

@objc public enum CTPanoramaControlMethod: Int {
    case motion
    case touch
    case rotate
}

@objc public class PanoView: UIView {
    
    var imageDictionary = [String: UIImage]()
    
    // MARK: Public properties
    @objc public var toolbar: UIToolbar?
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
    
    @objc public var hudToggle: HUD = .hide {
        didSet {
            toggleHUD(to: hudToggle)
        }
    }
    
    
    // MARK: Private properties
    var pursuitGraph = Graph()
    
    private let radius: CGFloat = 10
    
    public lazy var sceneView : SCNView = {
        let scnView = SCNView()
        return scnView
    }()
    
    private let scene = SCNScene()
    private let motionManager = CMMotionManager()
    private var roomNode: SCNNode?
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
    
    //MARK:-- Common Init
    func commonInit() {
        
        print("starting common")
        pursuitGraph =  GraphData.manager.populateGraph()
        
        //Fetching the first room and image
        
        guard let firstRoomID = pursuitGraph.firstRoomID else { return }
        
        guard let firstRoom = pursuitGraph.floorPlan[firstRoomID] else { return }
        
        guard let firstImageURL = firstRoom.imageURL else { return }
        
        if var firstImage = UIImage(named: firstImageURL){
            firstImage = firstImage.resize(image: firstImage)
            self.imageDictionary[firstImageURL] = firstImage
        }
        
        
        //Trying to fetch the rest of the images
        
        DispatchQueue.global(qos: .userInitiated).async {
            print("Fetching all the other images")
            for (_,room) in self.pursuitGraph.floorPlan where room.imageURL != self.pursuitGraph.firstRoomID{
                print("grabbing images")
                guard let imageURL = room.imageURL else { continue }
                
                //If image already exists
                if self.imageDictionary[imageURL] == nil {
                    if var newRoomImage = UIImage(named: imageURL){
                        newRoomImage = newRoomImage.resize(image: newRoomImage)
                        self.imageDictionary[imageURL] = newRoomImage
                    }
                }
            }
        }
        
        print("Done w/ floorplan")
        
        add(view: sceneView)
        
        scene.rootNode.addChildNode(cameraNode)
        yFov = 80
        resetCameraAngles()
        sceneView.scene = scene
        
        switchControlMethod(to: controlMethod)
        
        //Creating the node based on the first element of the floorplan
        
        createRoomNode(room: firstRoom)
        
        for (_, hotspot) in firstRoom.hotspots {
            if let name = hotspot.destination.name {
                createHotSpotNode(name: name, position: SCNVector3Make(hotspot.coordinates.0, hotspot.coordinates.1, hotspot.coordinates.2))
            }
        }
    }
    
    // MARK: Configuration helper methods
    
    private func createRoomNode(room: Room) {
        
        guard let imageURL = room.imageURL else { return }
        
        if imageDictionary[imageURL] == nil{
            if var image = UIImage(named: imageURL) {
                image = image.resize(image: image)
                imageDictionary[imageURL] = image
            }
        }
        
        if roomNode != nil{
            roomNode?.removeFromParentNode()
        }
        
        let sphere = SCNSphere(radius: radius)
        sphere.segmentCount = 300
        
        let material = SCNMaterial()
        
        DispatchQueue.main.async {
            material.diffuse.contents = self.imageDictionary[imageURL]
            material.diffuse.mipFilter = .nearest
            material.diffuse.magnificationFilter = .nearest
            material.diffuse.contentsTransform = SCNMatrix4MakeScale(-1, 1, 1)
            material.diffuse.wrapS = .repeat
            material.cullMode = .front
            
            sphere.firstMaterial = material
        }
        
        let sphereNode = SCNNode()
        sphereNode.geometry = sphere
        sphereNode.name = room.name
        
        //Rotating the sphere 180 degrees so that the camera node will face the the center of the photosphere.
        sphereNode.rotation = SCNVector4Make(0, 1, 0, Float(180).toRadians())
        
        roomNode = sphereNode
        
        //        guard let photoSphereNode = geometryNode else {return}
        //        scene.rootNode.addChildNode(photoSphereNode)
        scene.rootNode.addChildNode(roomNode!)
        resetCameraAngles()
    }
    
    /// Creates An Array Of CIBloom Filters
    ///
    /// - Returns: [CIFilter]?
    func addBloom() -> [CIFilter]? {
        let bloomFilter = CIFilter(name:"CIBloom")!
        bloomFilter.setValue(5.0, forKey: "inputIntensity")
        bloomFilter.setValue(10.0, forKey: "inputRadius")

        return [bloomFilter]
    }
    
    private func createHotSpotNode(name: String, position: SCNVector3){
        
        //Create invisible node to increase touch area
        let sphere = SCNSphere(radius: 0.5)
        sphere.firstMaterial = SCNMaterial(color: .clear)
        
        let newHotSpotNode = SCNNode()
        newHotSpotNode.geometry = sphere
        newHotSpotNode.position = position
        newHotSpotNode.name = name
        
        //Create the node the user will actually see to tap
        let colorSphere = SCNSphere(radius: 0.2)

        colorSphere.firstMaterial?.diffuse.contents = UIColor.systemGreen
        
        let colorNode = SCNNode()
        colorNode.geometry = colorSphere
        colorNode.position = position
        colorNode.name = name
    
        colorNode.animateUpAndDown()
        colorNode.highlightNodeWithDurarion(5)
        
        roomNode?.addChildNode(newHotSpotNode)
        roomNode?.addChildNode(colorNode)
    }
    
    private func enterRoom(selectedNode: SCNNode){
        
        guard let nodeName = selectedNode.name else { return }
        self.makeToast("You entered \(nodeName)")
        
        guard let destinationRoom = pursuitGraph.floorPlan[nodeName] else { return }
        
        //Resetting the field of view
        yFov = 80
        
        createRoomNode(room: destinationRoom)
        
        for (_, hotspot) in destinationRoom.hotspots{
            if let name = hotspot.destination.name {
                createHotSpotNode(name: name, position: SCNVector3Make(hotspot.coordinates.0, hotspot.coordinates.1, hotspot.coordinates.2))
            }
        }
    }
    
    private func replace(overlayView: UIView?, with newOverlayView: UIView?) {
        overlayView?.removeFromSuperview()
        guard let newOverlayView = newOverlayView else {return}
        add(view: newOverlayView)
    }
    
    private func toggleHUD(to method: HUD){
        if method == .show {
            toolbar?.isHidden = false
        }else{
            toolbar?.isHidden = true
        }
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
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            sceneView.addGestureRecognizer(tapGesture)
            
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
            startScale = Double(cameraNode.camera!.fieldOfView)
        case .changed:
            let fov = startScale / zoom
            if fov > 20 && fov < 80 {
                cameraNode.camera!.fieldOfView = CGFloat(fov)
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
                
                guard result.node.parent != scene.rootNode else {
                    print("You tapped on nothing")
                    
                    //toggle the HUD
                    if hudToggle == .hide {
                        hudToggle = .show
                    }else{
                        hudToggle = .hide
                    }
                    return
                }
                
                enterRoom(selectedNode: result.node)
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

