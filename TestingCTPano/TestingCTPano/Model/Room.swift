import UIKit
import SceneKit

public class Room{
    
    var name: String?
    var imageURL: String?
    var hotspots: [String:Hotspot]
    var startingAngle: Float?
    
    init() {
        self.hotspots = [String:Hotspot]()
    }
    
    func getHotspot(destinationName: String) -> Hotspot? {
        return hotspots[destinationName]
    }
}

public class Hotspot{
    var name: String?
    var destination: Room
    var coordinates: (Float, Float, Float)
    
    init() {
        self.destination = Room()
        self.coordinates = (0, 0, 0)
    }
    
    func updatePosition(newPosition: SCNVector3) {
        self.coordinates = (newPosition.x, newPosition.y, newPosition.z)
    }
}

