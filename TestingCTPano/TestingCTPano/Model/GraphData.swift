//
//  GraphData.swift
//  TestingCTPano
//
//  Created by Jack Wong on 2/1/20.
//  Copyright © 2020 Jack Wong. All rights reserved.
//

import Foundation

class GraphData{
    
    static let manager = GraphData()
    
    func populateGraph() -> Graph {
        
        let newGraph = Graph()
        
        //Creating Rooms
        let flexSpace = newGraph.addRoom(name: "flexspace", imageURL: "flexspace")
        
        let classroom2 = newGraph.addRoom(name: "classroom2", imageURL: "classroom2")
        
        let television = newGraph.addRoom(name: "tv", imageURL: "bioshockinfinite")
        
        //Creating Hotspots
        newGraph.addHotspot(source: flexSpace, destination: classroom2, coordinates: (-9.892502, -0.8068286, -1.216294))
        
        if let lastHotSpot = classroom2.hotspots.last{
            lastHotSpot.coordinates = (1.0734094, -0.56759614, 9.925603)
        }
        
        newGraph.addHotspot(source: flexSpace, destination: television, coordinates: (-2.0663686, -0.24952725, -9.780738))
        
        return newGraph
    }
}
