//
//  Room.swift
//  TestingCTPano
//
//  Created by Jack Wong on 1/30/20.
//  Copyright © 2020 Jack Wong. All rights reserved.
//

import UIKit
import SceneKit

struct Room {
    var imageURL: String
//    var nearbyRooms: [Room : Hotspot]
    var hotspots: [Hotspot]
}

struct Hotspot {
    var name: String
    var coordinates: SCNVector3
}

