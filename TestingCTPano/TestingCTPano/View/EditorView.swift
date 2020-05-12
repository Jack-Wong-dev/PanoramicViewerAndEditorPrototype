import UIKit
import SceneKit
import CoreMotion
import ImageIO

@objc public class EditorView: UIView {

    var imageDictionary = [String: UIImage]()

    // MARK: Public properties
    @objc public var fab: Floaty?
    @objc public var toolbar: UIToolbar?
    @objc public var movementHandler: ((_ rotationAngle: CGFloat, _ fieldOfViewAngle: CGFloat) -> Void)?
    @objc public var panSpeed = CGPoint(x: 0.005, y: 0.005)
    public var currentAngleY: Float = 0
    public var previousAngleY: Float = 0
    var currentRoom = Room()

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

    @objc public var tapPurpose: TapSelection = .selectNode {
        didSet {
            switch tapPurpose {
            case .selectNode:
                fab?.isHidden = false
            default:
                fab?.isHidden = true
            }
        }
    }

    // MARK: Private properties
    private var selectedGraph = Graph()
    private var editNode : SCNNode?
    private var nextRoom : Room?

    private let radius: CGFloat = 10
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
    
    public lazy var sceneView : SCNView = {
        let scnView = SCNView()
        return scnView
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
            return cameraNode.camera?.fieldOfView ?? 0
        }
        set {
            cameraNode.camera?.fieldOfView = newValue
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

    public convenience init(frame: CGRect, graph: Graph, room: Room) {
        self.init(frame: frame)
        self.selectedGraph = graph
        self.currentRoom = room
        // Force Swift to call the property observer by calling the setter from a non-init context
        commonInit()
    }

    deinit {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }

    private func commonInit(){
        add(view: sceneView)
        scene.rootNode.addChildNode(cameraNode)
        yFov = 80
        resetCameraAngles()
        sceneView.scene = scene
        sceneView.backgroundColor = UIColor.black

        createTour()
    }

    public func createTour() {

        guard let selectedRoomImageURL = currentRoom.imageURL else { return }

        if var firstImage = UIImage(named: selectedRoomImageURL){
            firstImage = firstImage.resize(image: firstImage)
            self.imageDictionary[selectedRoomImageURL] = firstImage
        }
        //Trying to fetch the rest of the images

        DispatchQueue.global(qos: .userInitiated).async {
            print("Fetching all the other images")
            for (_,room) in self.selectedGraph.floorPlan where room.imageURL != self.currentRoom.imageURL{
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

        switchControlMethod(to: controlMethod)

        createGeometryNode(room: currentRoom)

        for (_, hotspot) in currentRoom.hotspots {
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
//        sphereNode.rotation = SCNVector4Make(0, 1, 0, Float(180).toRadians())
        print("Room angle: \(String(describing: room.startingAngle))")
        currentAngleY = room.startingAngle ?? 180
        print("Current Angle Y : \(currentAngleY)")
        
        sphereNode.rotation = SCNVector4Make(0, 1, 0,  currentAngleY.toRadians())

        geometryNode = sphereNode

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

        colorSphere.firstMaterial?.diffuse.contents = #colorLiteral(red: 0.4256733358, green: 0.5473166108, blue: 0.3936028183, alpha: 1)

        let colorNode = SCNNode()
        colorNode.geometry = colorSphere
        colorNode.position = position
        colorNode.name = name
        
        colorNode.setHighlighted()
        
        colorNode.animateUpAndDown()
        colorNode.highlightNodeWithDurarion(10)

        geometryNode?.addChildNode(newHotSpotNode)
        geometryNode?.addChildNode(colorNode)
    }

    private func createNewHotSpotNode(name: String, position: SCNVector3) -> SCNNode{

        //Create invisible node to increase touch area
        let sphere = SCNSphere(radius: 0.5)
        sphere.firstMaterial = SCNMaterial(color: .clear)

        let newHotSpotNode = SCNNode()
        newHotSpotNode.geometry = sphere
        newHotSpotNode.position = position
        newHotSpotNode.name = name

        //Create the node the user will actually see to tap
        let colorSphere = SCNSphere(radius: 0.2)
        colorSphere.firstMaterial?.diffuse.contents = #colorLiteral(red: 0.4256733358, green: 0.5473166108, blue: 0.3936028183, alpha: 1)
        
        let colorNode = SCNNode()
        colorNode.geometry = colorSphere
        colorNode.position = position
        colorNode.name = name

        colorNode.animateUpAndDown()
        colorNode.highlightNodeWithDurarion(10)

        geometryNode?.addChildNode(newHotSpotNode)
        geometryNode?.addChildNode(colorNode)

        return colorNode
    }

    private func enterRoom(selectedNode: SCNNode){

        guard let nodeName = selectedNode.name else { return }
        self.makeToast("You entered \(nodeName)")

        guard let destinationRoom = selectedGraph.floorPlan[nodeName] else { return }

        //Resetting the field of view
        yFov = 80

        createGeometryNode(room: destinationRoom)

        for (_, hotspot) in destinationRoom.hotspots{
            if let name = hotspot.destination.name {
                createHotSpotNode(name: name, position: SCNVector3Make(hotspot.coordinates.0, hotspot.coordinates.1, hotspot.coordinates.2))
            }
        }

        currentRoom = destinationRoom
    }


    private func replace(overlayView: UIView?, with newOverlayView: UIView?) {
        overlayView?.removeFromSuperview()
        guard let newOverlayView = newOverlayView else {return}
        add(view: newOverlayView)
    }

    private func toggleHUD(to method: HUD){
        if method == .show {
            toolbar?.items![0].isEnabled = true
            toolbar?.isHidden = false
        }else{
            toolbar?.items![0].isEnabled = false
            toolbar?.isHidden = true
        }
    }
    
    private func switchControlMethod(to method: CTPanoramaControlMethod) {
        sceneView.gestureRecognizers?.removeAll()
        
        let pinchRec = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(pinchRec:)))
                  sceneView.addGestureRecognizer(pinchRec)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
                  sceneView.addGestureRecognizer(tapGesture)
        
        if method == .touch {
            let panGestureRec = UIPanGestureRecognizer(target: self, action: #selector(handlePan(panRec:)))
            sceneView.addGestureRecognizer(panGestureRec)
            
            if motionManager.isDeviceMotionActive {
                motionManager.stopDeviceMotionUpdates()
            }
        }else {
            let rotateGestureRec = UIPanGestureRecognizer(target: self, action: #selector(rotateObject(_:)))
            sceneView.addGestureRecognizer(rotateGestureRec)
        }
    }


    private func resetCameraAngles() {
        cameraNode.eulerAngles = SCNVector3Make(0, 0, 0)
        self.reportMovement(CGFloat(0), xFov.toRadians(), callHandler: false)
    }

    private func reportMovement(_ rotationAngle: CGFloat, _ fieldOfViewAngle: CGFloat, callHandler: Bool = true) {
        if callHandler {
            movementHandler?(rotationAngle, fieldOfViewAngle)
        }
    }

    // MARK: Gesture handling

    //MARK:-- Pan Gesture
    
    @objc func rotateObject(_ gesture: UIPanGestureRecognizer) {

        guard let nodeToRotate = geometryNode else { return }

            let translation = gesture.translation(in: gesture.view!)
            var newAngleY = (Float)(translation.x)*(Float)(Double.pi)/180.0
            newAngleY += currentAngleY

            nodeToRotate.eulerAngles.y = newAngleY

            if(gesture.state == .ended) { currentAngleY = newAngleY }

            print(nodeToRotate.eulerAngles)
    }
    
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

                switch tapPurpose {
                case .selectNode:
                    guard result.node.parent != scene.rootNode else {
                        print("You tapped on nothing")
                        return }

                    displayActionSheet(result.node)

                case .reposition:
                    guard result.node.parent == scene.rootNode else {

                        self.makeToast("You selected near an existing hotspot, try again!", point: CGPoint(x: self.bounds.width/2, y: self.bounds.height/8), title: "Derp!", image: UIImage(named: "derpface"), completion: nil)

                        return }

                    if let nodeToEdit = editNode{
                        print("Safely unwrapped node to edit")
                        previewNewPosition(selectedNode: nodeToEdit, newVector: newVector)
                    }

                case .createNode:

                    guard result.node.parent == scene.rootNode else {

                        self.makeToast("You selected near an existing hotspot, try again!", point: CGPoint(x: self.bounds.width/2, y: self.bounds.height/8), title: "Derp!", image: UIImage(named: "derpface"), completion: nil)

                        return }

                    let newHotSpot = createNewHotSpotNode(name: nextRoom!.name!, position: newVector)

                    previewNewHotspot(selectedNode: newHotSpot)

                case .createReverseNode:

                    guard result.node.parent == scene.rootNode else {

                        self.makeToast("You selected near an existing hotspot, try again!", point: CGPoint(x: self.bounds.width/2, y: self.bounds.height/8), title: "Derp!", image: UIImage(named: "derpface"), completion: nil)

                        return }

                    guard let nextRoom = nextRoom, let name = nextRoom.name else { return }

                    let newHotSpot = createNewHotSpotNode(name: name, position: newVector)

                    previewNewHotspot(selectedNode: newHotSpot)
                    
                case .none:
                    print("You're not supposed to select anything")
                }
            }
        }
    }

    private func previewNewHotspot(selectedNode: SCNNode){
        self.hideToast()

        let alertController = UIAlertController(title: "Confirm New Location", message: "Is this where you would like the location?", preferredStyle: .alert)

        let okayAction = UIAlertAction(title: "Yes", style: .default) { (action) in
            //TODO: dismiss the prompt

            guard let nextRoom = self.nextRoom else { return }

            DispatchQueue.global(qos: .userInitiated).async {

                guard let imageURL = nextRoom.imageURL else { return }

                if self.imageDictionary[imageURL] == nil {
                    if var newRoomImage = UIImage(named: imageURL){
                        newRoomImage = newRoomImage.resize(image: newRoomImage)
                        self.imageDictionary[imageURL] = newRoomImage
                    }
                }

            }

            if self.tapPurpose == .createNode{

                self.selectedGraph.addHotspot(source: self.currentRoom, destination: nextRoom, coordinates: (selectedNode.position.x, selectedNode.position.y, selectedNode.position.z))

                self.makeToast("creating new hotspot")

                self.createGeometryNode(room: nextRoom)

                for (_, hotspot) in nextRoom.hotspots{
                    if let name = hotspot.destination.name {
                        self.createHotSpotNode(name: name, position: SCNVector3Make(hotspot.coordinates.0, hotspot.coordinates.1, hotspot.coordinates.2))
                    }
                }
                //Switch
                let temp = self.nextRoom!
                self.nextRoom = self.currentRoom
                self.currentRoom = temp
                self.tapPurpose = .createReverseNode

                self.hudToggle = .hide

                self.makeToast("Tap where you would like to place the hotspot back to \(nextRoom.name!)", point: CGPoint(x: self.bounds.width/2, y: self.bounds.height/8), title: "Tap Location", image: UIImage(named: "funnyface"), completion: nil)


            }else if self.tapPurpose == .createReverseNode{

                self.selectedGraph.updatePosition(source: self.currentRoom, destination: nextRoom, newPosition: (selectedNode.position.x, selectedNode.position.y, selectedNode.position.z))

                //Update the graph structure here

                self.tapPurpose = .selectNode

                self.makeToast(nil, point: CGPoint(x: self.bounds.width/2, y: self.bounds.height/1.5), title: nil, image: UIImage(named: "happyface"), completion: nil)
                self.makeToast("Success!")
            }
        }


        let cancelAction = UIAlertAction(title: "No", style: .default) { (action) in

            self.makeToast("Tap where you would like to place the hotspot", point: CGPoint(x: self.bounds.width/2, y: self.bounds.height/8), title: "Tap Location", image: UIImage(named: "funnyface"), completion: nil)

            self.geometryNode?.childNodes.filter{$0.name == selectedNode.name}.forEach({ $0.removeFromParentNode()
            })
        }

        alertController.addAction(okayAction)
        alertController.addAction(cancelAction)

        var topController = UIApplication.shared.windows.first{ $0.isKeyWindow }?.rootViewController


        alertController.popoverPresentationController?.sourceView = self
        //...
        hideToast()

        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }

        topController?.present(alertController, animated: true, completion: nil)

    }

    private func previewNewPosition(selectedNode: SCNNode, newVector: SCNVector3){

        let previousCoordinates = selectedNode.position

        geometryNode?.childNodes.filter{$0.name == selectedNode.name}.forEach({ $0.position = newVector
        })

        let alertController = UIAlertController(title: "Confirm New Location", message: "What would you like to do?", preferredStyle: .alert)

        let okayAction = UIAlertAction(title: "Yes", style: .default) { (action) in
            //TODO: dismiss the prompt

            let room = self.selectedGraph.getRoom(name: self.geometryNode!.name!)
            let hotspot = room?.getHotspot(destinationName: selectedNode.name!)
            hotspot?.coordinates = (selectedNode.position.x,selectedNode.position.y,selectedNode.position.z)

            self.tapPurpose = .selectNode

            self.hideToast()

            self.makeToast(nil, point: CGPoint(x: self.bounds.width/2, y: self.bounds.height/1.5), title: nil, image: UIImage(named: "happyface"), completion: nil)
            self.makeToast("Success!")
            self.hudToggle = .hide
        }


        let cancelAction = UIAlertAction(title: "No", style: .default) { (action) in

            self.makeToast("Tap where you would like to place the hotspot", point: CGPoint(x: self.bounds.width/2, y: self.bounds.height/8), title: "Tap Location", image: UIImage(named: "funnyface"), completion: nil)

            self.geometryNode?.childNodes.filter{$0.name == selectedNode.name}.forEach({ $0.position = previousCoordinates
            })
        }

        alertController.addAction(okayAction)
        alertController.addAction(cancelAction)

        var topController = UIApplication.shared.windows.first{ $0.isKeyWindow }?.rootViewController


        alertController.popoverPresentationController?.sourceView = self
        //...
        hideToast()

        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }

        topController?.present(alertController, animated: true, completion: nil)

    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size.width != prevBounds.size.width || bounds.size.height != prevBounds.size.height {
            sceneView.setNeedsDisplay()
            reportMovement(CGFloat(-cameraNode.eulerAngles.y), xFov.toRadians(), callHandler: false)
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
            self.tapPurpose = .reposition
            self.editNode = selectedNode

            self.hudToggle = .show
        }

        //MARK: -- Delete HotSpot
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in

            //Update the changes to our graph
            guard let destinationName = selectedNode.name, let sourceName = self.geometryNode?.name else { return }

            guard  let sourceRoom = self.selectedGraph.getRoom(name: sourceName), let destinationRoom = self.selectedGraph.getRoom(name: destinationName) else { return }

            self.selectedGraph.deleteHotSpot(source: sourceRoom, destination: destinationRoom)

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

        var topController = UIApplication.shared.windows.first{ $0.isKeyWindow }?.rootViewController


        alertController.popoverPresentationController?.sourceView = self
        //...
        hideToast()

        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }

        topController?.present(alertController, animated: true, completion: nil)
    }

    func displayRoomList(){

        let alertController = UIAlertController(title: "Select Destination!", message: "Please select the destination for \(currentRoom.name!)", preferredStyle: .alert)

        var everyRoom = [Room]()
        for (_,room)in selectedGraph.floorPlan{
            everyRoom.append(room)
        }
        everyRoom.sort{ $0.name! < $1.name! }

        //Adding an action
        for room in everyRoom where room.name != self.geometryNode?.name {

            var hotspotExists: Bool = false

            //Check if hotspot exists
            if self.currentRoom.getHotspot(destinationName: room.name!) != nil{
                hotspotExists = true
            }

            let title = hotspotExists ? "\(room.name!) (Already Created)" : room.name

            let roomAction = UIAlertAction(title: title, style: .default, handler: { (action) in

                print("you picked \(room.name!)")
                self.nextRoom = room
                self.tapPurpose = .createNode

                self.hudToggle = .show

                self.makeToast("Tap where you would like to place the hotspot", point: CGPoint(x: self.bounds.width/2, y: self.bounds.height/8), title: "Tap Location", image: UIImage(named: "funnyface"), completion: nil)
            })

            if hotspotExists{
                roomAction.isEnabled = false
            }

            alertController.addAction(roomAction)

        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(cancelAction)
        //...

        var topController = UIApplication.shared.windows.first{ $0.isKeyWindow }?.rootViewController

        alertController.popoverPresentationController?.sourceView = self
        //...
        hideToast()

        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }

        topController?.present(alertController, animated: true, completion: nil)
    }
    
    func saveNewCameraPosition(){
        
        print("Rotation.w \(String(describing: geometryNode?.rotation.w))")
        
        if var newValue = geometryNode?.rotation.w {
            newValue = newValue.toDegrees()
            selectedGraph.updateStaringAngle(source: currentRoom, angle: newValue)
        }
        
        
    }
}


extension CMDeviceMotion {

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

