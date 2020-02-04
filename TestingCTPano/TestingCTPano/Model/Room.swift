import Foundation

public class Room {
    var name: String?
    var imageURL: String?
    var hotspots: [Hotspot]
    
    init() {
        self.hotspots = [Hotspot]()
    }
}

public class Hotspot {
    var neighbor: Room
    var coordinates: (Float, Float, Float)
    
    init() {
        self.neighbor = Room()
        self.coordinates = (0, 0, 0)
    }
    
}

public class Graph {
    var floorPlan: [Room]
    
    init() {
        self.floorPlan = [Room]()
    }
    
    func addRoom(name: String?, imageURL: String?) -> Room {
        let newRoom = Room()
        newRoom.name = name
        newRoom.imageURL = imageURL
        floorPlan.append(newRoom)
        return newRoom
    }
    
    func addHotspot(source: Room, destination: Room, coordinates: (Float, Float, Float)) {
        let hotspot = Hotspot()
        hotspot.neighbor = destination
        hotspot.coordinates = coordinates
        source.hotspots.append(hotspot)
        
        let reverseHotspot = Hotspot()
        reverseHotspot.neighbor = source
        destination.hotspots.append(reverseHotspot)
    }
}
