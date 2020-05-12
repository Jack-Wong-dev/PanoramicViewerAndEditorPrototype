import UIKit
import SceneKit

public class Graph {
    
    var floorPlan: [String:Room]
    var firstRoomID: String?
    
    //MARK: Retrieve Room - Completed
    func getRoom(name: String) -> Room?{
        let formattedName = name.lowercased()
        return floorPlan[formattedName]
    }
    
    //MARK: Check if name for room exists
    func checkNameExists(name: String) -> Bool{
        let formattedName = name.lowercased()
        
        if floorPlan[formattedName] != nil{
            return true
        }
            
        return false
    }
    
    //MARK: Add Room - Completed
    func addRoom(name: String?, imageURL: String?) -> Room {
        let newRoom = Room()
        
        newRoom.name = name?.lowercased()
        newRoom.imageURL = imageURL
        
        if let name = name{
            floorPlan[name] = newRoom
        }
        return newRoom
    }
    
    //MARK:-- Retrieve Room - Completed
    func deleteRoom(selectedRoom: Room){
        
        guard let name = selectedRoom.name else {return}
        
        floorPlan[name] = nil
        
        //Iterate through every room
        for (_ , room) in floorPlan{
            //the hotspots that are linked to the delete room to be deleted
            room.hotspots[name] = nil
        }
    }
    
    //MARK: Add Hotspot - Completed
    func addHotspot(source: Room, destination: Room, coordinates: (Float, Float, Float)) {
        let hotspot = Hotspot()
        
        guard let sourceName = source.name, let destinationName = destination.name else{ return }
        hotspot.name = destinationName
        hotspot.destination = destination
        hotspot.coordinates = coordinates
        source.hotspots[destinationName] = hotspot
        
        let reverseHotspot = Hotspot()
        reverseHotspot.name = sourceName
        reverseHotspot.destination = source
        destination.hotspots[sourceName] = reverseHotspot
    }
    
    //MARK: Delete Hotspot - Completed
    func deleteHotSpot(source: Room, destination: Room) {
        guard let sourceName = source.name, let destinationName = destination.name else{ return }
        source.hotspots[destinationName] = nil
        destination.hotspots[sourceName] = nil
    }
    
    //MARK:-- Update Coordinates - Completed
    func updatePosition(source: Room, destination: Room, newPosition: (Float,Float,Float)) {
        
        guard let sourceName = source.name, let destinationName = destination.name else{ return }
        floorPlan[sourceName]?.hotspots[destinationName]?.coordinates = newPosition
    }
    
    func updateStaringAngle(source: Room, angle: Float){
        print("New Angle: \(angle)")
        source.startingAngle = angle
    }
    
    init() {
        self.floorPlan = [String:Room]()
    }
}

class GraphData{
    
    static let manager = GraphData()
    
    func populateGraph() -> Graph {
        
        let newGraph = Graph()
        
        //Creating Rooms
        let flexSpace = newGraph.addRoom(name: "flexspace", imageURL: "flexspace")
                
        let classroom2 = newGraph.addRoom(name: "classroom2", imageURL: "classroom2")
        
        let television = newGraph.addRoom(name: "tv", imageURL: "bioshock")
        
        let outside = newGraph.addRoom(name: "outside", imageURL: "PursuitOutside")
        
        //Creating Hotspots
        newGraph.addHotspot(source: flexSpace, destination: classroom2, coordinates: (-9.892502, -0.8068286, -1.216294))
        
        //Room -> Hotspot[name of destination] -> update coordinates
        newGraph.updatePosition(source: classroom2, destination: flexSpace, newPosition: (1.0734094, -0.56759614, 9.925603))
        
        newGraph.addHotspot(source: flexSpace, destination: television, coordinates: (-2.0663686, -0.24952725, -9.780738))
        
        newGraph.updatePosition(source: television, destination: flexSpace, newPosition: (4.5396996, 0.098314874,  -8.908977))
        
        newGraph.addHotspot(source: classroom2, destination: outside, coordinates: (2.5361452, -2.2858243, -9.398544))
        
        newGraph.updatePosition(source: outside, destination: classroom2, newPosition: (-8.680619, 4.911766, -0.72091013))
        
        newGraph.firstRoomID = "flexspace"
        
        return newGraph
    }
}


class EditorGraphData{
    
    static let manager = EditorGraphData()
    
    func populateGraph() -> Graph {
        
        let newGraph = Graph()
        
        //Creating Rooms
        let flexSpace = newGraph.addRoom(name: "flexspace", imageURL: "flexspace")
        
//        flexSpace.startingAngle = 90

        let _ = newGraph.addRoom(name: "classroom2", imageURL: "classroom2")
        
        let _ = newGraph.addRoom(name: "tv", imageURL: "bioshock")
        
        let _ = newGraph.addRoom(name: "outside", imageURL: "PursuitOutside")
        
//        //Creating Hotspots
//        newGraph.addHotspot(source: flexSpace, destination: classroom2, coordinates: (-9.892502, -0.8068286, -1.216294))
//
//        //Room -> Hotspot[name of destination] -> update coordinates
//        newGraph.updatePosition(source: classroom2, destination: flexSpace, newPosition: (1.0734094, -0.56759614, 9.925603))
//
//        newGraph.addHotspot(source: flexSpace, destination: television, coordinates: (-2.0663686, -0.24952725, -9.780738))
//
//        newGraph.updatePosition(source: television, destination: flexSpace, newPosition: (4.5396996, 0.098314874,  -8.908977))
//
//        newGraph.addHotspot(source: classroom2, destination: outside, coordinates: (2.5361452, -2.2858243, -9.398544))
//
//        newGraph.updatePosition(source: outside, destination: classroom2, newPosition: (-8.680619, 4.911766, -0.72091013))
//
        newGraph.firstRoomID = "flexspace"
        
        return newGraph
    }
}

class AllRoomData {
    
   static var imageCollection = [RoomData]()
    
    func addRoomData(data: RoomData){
     AllRoomData.imageCollection.append(data)
    }
    
}

struct RoomData {
    var image: UIImage
    var name: String
}

protocol DataSendingProtocol: AnyObject {
    func sendDataToCreateListingVC(roomData: RoomData)
}

