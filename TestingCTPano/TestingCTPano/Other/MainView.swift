//
//  PanoView.swift
//  TestingCTPano
//
//  Created by Jack Wong on 1/27/20.
//  Copyright © 2020 Jack Wong. All rights reserved.
//

import UIKit
import ImageIO

class MainView: UIView {
    public lazy var panoView: CTPanoramaView = {
        
        let pV = CTPanoramaView()
        return pV
    }()
    
    public lazy var compassView: CTPieSliceView = {
        let cV = CTPieSliceView()
        return cV
    }()
    
    public lazy var motionButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.text = "Touch/Motion"
        button.addTarget(self, action: #selector(motionTypeTapped),
                         for: .touchUpInside)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: UIScreen.main.bounds)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func commonInit(){
        addSubviews()
        setConstraints()
        panoView.compass = compassView
    }
    
    func addSubviews(){
        addSubview(panoView)
        addSubview(compassView)
        addSubview(motionButton)
    }
    
    func setConstraints() {
        setPanoViewConstraints()
        setCompassPieConstraints()
        setOptionButtonConstraints()
    }
    
    @objc func motionTypeTapped(){
        if panoView.controlMethod == .touch{
            panoView.controlMethod = .motion
        }else{
            panoView.controlMethod = .touch
        }
    }
    
    //    @objc func panoramaTypeTapped() {
    //
    //        if panoView.panoramaType == .spherical {
    //            loadCylindricalImage()
    //        } else {
    //            loadSphericalImage()
    //        }
    //    }
    
//    func loadSphericalImage() {
//        
//        self.panoView.image = UIImage(named: "pursuit")
//        
//    }
//    
//    func loadCylindricalImage() {
//        self.panoView.image = UIImage(named: "cylindrical")
//    }
    

    
}

extension MainView {
    private func setPanoViewConstraints(){
        panoView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            panoView.topAnchor.constraint(equalTo: topAnchor),
            panoView.leadingAnchor.constraint(equalTo: leadingAnchor),
            panoView.trailingAnchor.constraint(equalTo: trailingAnchor),
            panoView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
    }
    
    private func setCompassPieConstraints(){
        compassView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            compassView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            compassView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            compassView.heightAnchor.constraint(equalToConstant: 40),
            compassView.widthAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setOptionButtonConstraints(){
        motionButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            motionButton.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            motionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }
    
    
}
