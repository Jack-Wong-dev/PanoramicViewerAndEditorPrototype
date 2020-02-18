import UIKit
import SceneKit
import CoreMotion
import ImageIO

@objc public enum TapSelection: Int {
    case selectPosition
    case nodeSelection
}

@objc public class EditorView: UIView {
    
    var imageDictionary = [String: UIImage]()
    
    // MARK: Public properties
    //    public var pursuitGraph = Graph()
    @objc public var toolbar: UIToolbar?
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
    
    @objc public var hudToggle: HUD = .show {
        didSet {
            toggleHUD(to: hudToggle)
        }
    }
    
    
    @objc public var tapToggle: TapSelection = .nodeSelection {
        didSet {
            toggleHUD(to: hudToggle)
        }
    }
    
    // MARK: Private properties
    private var pursuitGraph = Graph()
    private var editNode : SCNNode?
    
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
        
        add(view: sceneView)
        
        scene.rootNode.addChildNode(cameraNode)
        yFov = 80
        resetCameraAngles()
        sceneView.scene = scene
        sceneView.backgroundColor = UIColor.black
        
        switchControlMethod(to: controlMethod)
        
        //Creating the node based on the first element of the floorplan
        createGeometryNode(room: firstRoom)
        
        for (_, hotspot) in firstRoom.hotspots {
            if let name = hotspot.destination.name {
                createHotSpotNode(name: name, position: SCNVector3Make(hotspot.coordinates.0, hotspot.coordinates.1, hotspot.coordinates.2))
            }
        }
    }
    // MARK: Configuration helper methods
    
    private func createGeometryNode(room: Room) {
        
        guard let imageURL = room.imageURL else { return }
        
        if imageDictionary[imageURL] == nil{
            if var image = UIImage(named: imageURL) {
                image = image.resize(image: image)
                imageDictionary[imageURL] = image
            }
        }
        
        if geometryNode != nil{
            geometryNode?.removeFromParentNode()
        }
        
        let sphere = SCNSphere(radius: radius)
        sphere.segmentCount = 300
        
        let material = SCNMaterial()
        
        DispatchQueue.main.async {
            material.diffuse.contents = self.imageDictionary[imageURL]!
            //        material.diffuse.contents = selectedImage.resize(image: selectedImage)
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
        
        geometryNode = sphereNode
        
        //        guard let photoSphereNode = geometryNode else {return}
        //        scene.rootNode.addChildNode(photoSphereNode)
        scene.rootNode.addChildNode(geometryNode!)
        resetCameraAngles()
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
        colorSphere.firstMaterial?.diffuse.contents = UIColor.green
        
        let colorNode = SCNNode()
        colorNode.geometry = colorSphere
        colorNode.position = position
        colorNode.name = name
        
        //Animate the color node to hover
        let moveUp = SCNAction.moveBy(x: 0, y: 0.05, z: 0, duration: 1)
        moveUp.timingMode = .easeInEaseOut;
        let moveDown = SCNAction.moveBy(x: 0, y: -0.05, z: 0, duration: 1)
        moveDown.timingMode = .easeInEaseOut;
        let moveSequence = SCNAction.sequence([moveUp,moveDown])
        let moveLoop = SCNAction.repeatForever(moveSequence)
        colorNode.runAction(moveLoop)
        
        geometryNode?.addChildNode(newHotSpotNode)
        geometryNode?.addChildNode(colorNode)
    }
    
    private func enterRoom(selectedNode: SCNNode){
        
        guard let nodeName = selectedNode.name else { return }
        self.makeToast("You entered \(nodeName)")
        
        guard let destinationRoom = pursuitGraph.floorPlan[nodeName] else { return }
        
        //Resetting the field of view
        yFov = 80
        
        //        createGeometryNode(imageURL: destinationRoom.imageURL)
        createGeometryNode(room: destinationRoom)
        
        for (_, hotspot) in destinationRoom.hotspots{
            if let name = hotspot.destination.name {
                createHotSpotNode(name: name, position: SCNVector3Make(hotspot.coordinates.0, hotspot.coordinates.1, hotspot.coordinates.2))
            }
        }
    }
    
    //MARK:- User creating Destination Hotspot
    private func createNewHotspot(){
        
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
        compass?.updateUI(rotationAngle: rotationAngle, fieldOfViewAngle: fieldOfViewAngle)
        if callHandler {
            movementHandler?(rotationAngle, fieldOfViewAngle)
        }
    }
    
    // MARK: Gesture handling
    
    //MARK:-- Pan Gesture
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
    
    //MARK:-- Pinch Gesture
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
    //MARK:-- Tap Gesture
    @objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        if gestureRecognize.state == .ended{
            
            let scnView = sceneView
            
            //Check what nodes are tapped
            let touchLocation = gestureRecognize.location(in: scnView)
            let hitResults = scnView.hitTest(touchLocation, options: nil)
            //Show tapped coordinates
            
            var newVector = SCNVector3Make(0, 0, 0)
            
            if hitResults.count > 0 {
                // retrieved the first clicked object
                let result: SCNHitTestResult = hitResults[0]
                let vect: SCNVector3 = result.localCoordinates
                print(vect)
                newVector = vect
                print("new vector is: \(newVector)")
            }
            if let result = hitResults.first {
                
                switch tapToggle {
                    
                case .nodeSelection:
                    print("Selecting Node...")
                    guard result.node.parent != scene.rootNode else {
                        print("You tapped on nothing")
                        return }
                    
                    displayActionSheet(result.node)
                    
                case .selectPosition:
                    print("Selecting Position....")
                    
                    guard result.node.parent == scene.rootNode else {
                        
                        self.makeToast("You selected near an existing hotspot, try again!", point: CGPoint(x: self.bounds.width/2, y: self.bounds.height/8), title: "Derp!", image: UIImage(named: "derpface"), completion: nil)
                        
                        return }
                    
                    if let nodeToEdit = editNode{
                        print("Safely unwrapped node to edit")
                        getNewCoordinates(selectedNode: nodeToEdit, newVector: newVector)
                    }
                }
            }
        }
    }
    
    private func getNewCoordinates(selectedNode: SCNNode, newVector: SCNVector3){
        
        let previousCoordinates = selectedNode.position
        
        geometryNode?.childNodes.filter{$0.name == selectedNode.name}.forEach({ $0.position = newVector
        })
        
        let alertController = UIAlertController(title: "Confirm New Location", message: "What would you like to do?", preferredStyle: .alert)
        
        let okayAction = UIAlertAction(title: "Yes", style: .default) { (action) in
            //TODO: dismiss the prompt
            
            let room = self.pursuitGraph.getRoom(name: self.geometryNode!.name!)
            let hotspot = room?.getHotspot(destinationName: selectedNode.name!)
            hotspot?.coordinates = (selectedNode.position.x,selectedNode.position.y,selectedNode.position.z)
            
            self.tapToggle = .nodeSelection
            
            //            self.toolbar?.items?[1].isEnabled = false
            self.toolbar?.items?[0].tintColor = .clear
            
            self.hideToast()
            
            self.makeToast(nil, point: CGPoint(x: self.bounds.width/2, y: self.bounds.height/1.5), title: nil, image: UIImage(named: "happyface"), completion: nil)
            self.makeToast("Success!")
        }
        
        
        let cancelAction = UIAlertAction(title: "No", style: .default) { (action) in
            
            self.makeToast("Tap where you would like to place the hotspot", point: CGPoint(x: self.bounds.width/2, y: self.bounds.height/8), title: "Tap Location", image: UIImage(named: "funnyface"), completion: nil)
            
            self.geometryNode?.childNodes.filter{$0.name == selectedNode.name}.forEach({ $0.position = previousCoordinates
            })
        }
        
        alertController.addAction(okayAction)
        alertController.addAction(cancelAction)
        
        var rootViewController = UIApplication.shared.windows.first{ $0.isKeyWindow }?.rootViewController
        
        if let navigationController = rootViewController as? UINavigationController {
            rootViewController = navigationController.viewControllers.first
        }
        if let tabBarController = rootViewController as? UITabBarController {
            rootViewController = tabBarController.selectedViewController
        }
        alertController.popoverPresentationController?.sourceView = self
        //...
        hideToast()
        rootViewController?.present(alertController, animated: true, completion: nil)
        
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

extension EditorView{
    
    private func displayActionSheet(_ selectedNode: SCNNode){
        
        let alertController = UIAlertController(title: "\(selectedNode.name!)", message: "What would you like to do?", preferredStyle: .alert)
        
        let enterAction = UIAlertAction(title: "Enter", style: .default) {
            (action) in
            self.enterRoom(selectedNode: selectedNode)
        }
        
        //MARK: -- Reposition HotSpot
        let repositionAction = UIAlertAction(title: "Move Position", style: .default) { (action ) in
            
            self.makeToast("Tap where you would like to place the hotspot", point: CGPoint(x: self.bounds.width/2, y: self.bounds.height/8), title: "Tap Location", image: UIImage(named: "funnyface"), completion: nil)
            self.tapToggle = .selectPosition
            self.editNode = selectedNode
            
            self.toolbar?.items?[0].isEnabled = true
            self.toolbar?.items?[0].tintColor = .white
        }
        
        //MARK: -- Delete HotSpot
               let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
                   
                   //Update the changes to our graph
                   guard let destinationName = selectedNode.name, let sourceName = self.geometryNode?.name else { return }
                   
                   guard  let sourceRoom = self.pursuitGraph.getRoom(name: sourceName), let destinationRoom = self.pursuitGraph.getRoom(name: destinationName) else { return }
                   
                   self.pursuitGraph.deleteHotSpot(source: sourceRoom, destination: destinationRoom)
                   
                   //Remove all child nodes with said name (This is because we created two identical hotspot nodes, but one is larger but invisible to increase touch area)
                   self.geometryNode?.childNodes.filter{$0.name == selectedNode.name}.forEach({ $0.removeFromParentNode()
                   })
               }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(enterAction)
        alertController.addAction(repositionAction)
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        //...
        var rootViewController = UIApplication.shared.windows.first{ $0.isKeyWindow }?.rootViewController
        
        if let navigationController = rootViewController as? UINavigationController {
            rootViewController = navigationController.viewControllers.first
        }
        if let tabBarController = rootViewController as? UITabBarController {
            rootViewController = tabBarController.selectedViewController
        }
        alertController.popoverPresentationController?.sourceView = self
        //...
        rootViewController?.present(alertController, animated: true, completion: nil)
    }
    
}

