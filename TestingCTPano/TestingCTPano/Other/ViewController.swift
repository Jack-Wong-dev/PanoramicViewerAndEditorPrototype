//
//  ViewController.swift
//  TestingCTPano
//
//  Created by Jack Wong on 1/21/20.
//  Copyright © 2020 Jack Wong. All rights reserved.
//

import UIKit
import ImageIO


class AlternateViewController: UIViewController {
    
    let mainView = MainView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(mainView)
//        mainView.loadSphericalImage()
    }
    
//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        return .all
//    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        print("Landscape Mode: \(UIDevice.current.orientation.isLandscape)")
        
    }
    
   
    
}

