//  Created by Jack Wong on 2/4/20.
//  Copyright © 2020 Jack Wong. All rights reserved.
//

import UIKit
import SceneKit
import CoreMotion

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

extension UIView {
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

extension FloatingPoint {
    func toDegrees() -> Self {
        return self * 180 / .pi
    }

    func toRadians() -> Self {
        return self * .pi / 180
    }
}

extension GLKQuaternion {
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

extension SCNNode{
    
    func animateUpAndDown(){
        //Animate the color node to hover
        let moveUp = SCNAction.moveBy(x: 0, y: 0.05, z: 0, duration: 1)
        moveUp.timingMode = .easeInEaseOut;
        let moveDown = SCNAction.moveBy(x: 0, y: -0.05, z: 0, duration: 1)
        moveDown.timingMode = .easeInEaseOut;
        let moveSequence = SCNAction.sequence([moveUp,moveDown])
        let moveLoop = SCNAction.repeatForever(moveSequence)
        self.runAction(moveLoop)
    }

    /// Creates A Pulsing Animation On An Infinite Loop
    ///
    /// - Parameter duration: TimeInterval
    func highlightNodeWithDurarion(_ duration: TimeInterval){

        //1. Create An SCNAction Which Emmits A Red Colour Over The Passed Duration Parameter
        let highlightAction = SCNAction.customAction(duration: duration) { (node, elapsedTime) in

            let color = UIColor(red: elapsedTime/CGFloat(duration), green: 0, blue: 0, alpha: 1)
            let currentMaterial = self.geometry?.firstMaterial
            currentMaterial?.emission.contents = color

        }

        //2. Create An SCNAction Which Removes The Red Emissio Colour Over The Passed Duration Parameter
        let unHighlightAction = SCNAction.customAction(duration: duration) { (node, elapsedTime) in
            let color = UIColor(red: CGFloat(1) - elapsedTime/CGFloat(duration), green: 0, blue: 0, alpha: 1)
            let currentMaterial = self.geometry?.firstMaterial
            currentMaterial?.emission.contents = color

        }

        //3. Create An SCNAction Sequence Which Runs The Actions
        let pulseSequence = SCNAction.sequence([highlightAction, unHighlightAction])

        //4. Set The Loop As Infinitie
        let infiniteLoop = SCNAction.repeatForever(pulseSequence)

        //5. Run The Action
        self.runAction(infiniteLoop)
    }
    
    func setHighlighted( _ highlighted : Bool = true, _ highlightedBitMask : Int = 2 ) {
        categoryBitMask = highlightedBitMask
        for child in self.childNodes {
            child.setHighlighted()
        }
    }
}


