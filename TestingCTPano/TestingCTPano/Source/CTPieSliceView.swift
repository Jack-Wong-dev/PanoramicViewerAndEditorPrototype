//
//  CTPieSliceView.swift
//  TestingCTPano
//
//  Created by Jack Wong on 1/21/20.
//  Copyright © 2020 Jack Wong. All rights reserved.
//

import UIKit

@IBDesignable @objcMembers public class CTPieSliceView: UIView {

    @IBInspectable var sliceAngle: CGFloat = .pi/2 {
        didSet { setNeedsDisplay() }
    }

    @IBInspectable var sliceColor: UIColor = UIColor(red: 254/255, green: 85/255, blue: 84/255, alpha: 1){
        didSet { setNeedsDisplay() }
    }

    @IBInspectable var outerRingColor: UIColor = UIColor(red: 255/255, green: 251/255, blue: 56/255, alpha: 1) {
        didSet { setNeedsDisplay() }
    }

    @IBInspectable var bgColor: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5) {
        didSet { setNeedsDisplay() }
    }

    #if !TARGET_INTERFACE_BUILDER

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    #endif

    func commonInit() {
        backgroundColor = UIColor.clear
        contentMode = .redraw
    }

    public override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let ctx = UIGraphicsGetCurrentContext() else {return}

        // Draw the background
        ctx.addEllipse(in: bounds)
        ctx.setFillColor(bgColor.cgColor)
        ctx.fillPath()

        // Draw the outer ring
//        ctx.addEllipse(in: bounds.insetBy(dx: 2, dy: 2))
//        ctx.setStrokeColor(outerRingColor.cgColor)
//        ctx.setLineWidth(2)
//        ctx.strokePath()

        let radius = (bounds.width/2)-6
        let localCenter = CGPoint(x: bounds.size.width/2, y: bounds.size.height/2)
        let startAngle = -(.pi/2 + sliceAngle/2)
        let endAngle = startAngle + sliceAngle
        let arcStartPoint = CGPoint(x: localCenter.x + radius * cos(startAngle),
                                    y: localCenter.y + radius * sin(startAngle))

        // Draw the inner slice
        ctx.beginPath()
        ctx.move(to: localCenter)
        ctx.addLine(to: arcStartPoint)
        ctx.addArc(center: localCenter, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        ctx.closePath()
        ctx.setFillColor(sliceColor.cgColor)
        ctx.fillPath()
    }
}

extension CTPieSliceView: CTPanoramaCompass {
    public func updateUI(rotationAngle: CGFloat, fieldOfViewAngle: CGFloat) {
        sliceAngle = fieldOfViewAngle
        transform = CGAffineTransform.identity.rotated(by: rotationAngle)
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI
struct PieSliceRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        return CTPieSliceView()
    }
    
    func updateUIView(_ view: UIView, context: Context) {
    }
}

struct PieSliceSampleView: View {
    var body: some View{
        PieSliceRepresentable()
    }
}

@available(iOS 13.0, *)
struct PieSliceSampleView_Preview: PreviewProvider {
    static var previews: some View {
        PieSliceSampleView()
    }
}
#endif
