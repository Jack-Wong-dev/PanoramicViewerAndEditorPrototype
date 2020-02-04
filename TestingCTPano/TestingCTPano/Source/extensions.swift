//
//  extensions.swift
//  TestingCTPano
//
//  Created by Jack Wong on 2/4/20.
//  Copyright © 2020 Jack Wong. All rights reserved.
//

import UIKit
import SceneKit

extension UIImage {
    
    func resize(image: UIImage) -> UIImage{
        if image.size.width <= 8192 {
            return image
        }else{
            UIGraphicsBeginImageContext(CGSize(width: 8192, height: 4096))
                   image.draw(in: CGRect(x: 0, y: 0, width: 8192, height: 4096))
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
                   UIGraphicsEndImageContext()
            return newImage!
        }
    }
}

extension SCNMaterial {
    convenience init(color: UIColor) {
        self.init()
        diffuse.contents = color
    }
    convenience init(image: UIImage) {
        self.init()
        diffuse.contents = image
    }
}


