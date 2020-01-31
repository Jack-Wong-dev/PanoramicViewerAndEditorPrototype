import Foundation

public class Room {
    var name: String?
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
    
    func addRoom(name: String?) -> Room {
        let newRoom = Room()
        newRoom.name = name
        floorPlan.append(newRoom)
        return newRoom
    }
    
    func addHotspot(source: Room, neighbor: Room, coordinates: (Float, Float, Float)) {
        let hotspot = Hotspot()
        hotspot.neighbor = neighbor
        hotspot.coordinates = coordinates
        source.hotspots.append(hotspot)
        
        let reverseHotspot = Hotspot()
        reverseHotspot.neighbor = source
        neighbor.hotspots.append(reverseHotspot)
    }
    
    
}
//
//
//let pursuitGraph = Graph()
//let classroom = pursuitGraph.addRoom(name: "classroom2")
//let bathroom = pursuitGraph.addRoom(name: "bathroom")
//
//pursuitGraph.addHotspot(source: classroom, neighbor: bathroom, coordinates: (420, 69, 33))
//
//var hotSpotCount = 0
//
//for i in pursuitGraph.floorPlan{
//    for j in i.hotspots{
//        print(j.coordinates)
//        hotSpotCount += 1
//    }
//}
//
////print(hotSpotCount)

