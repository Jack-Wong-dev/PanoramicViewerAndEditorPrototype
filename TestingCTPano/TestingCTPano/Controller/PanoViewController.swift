//
//  PanoViewController.swift
//  TestingCTPano
//
//  Created by Jack Wong on 1/27/20.
//  Copyright © 2020 Jack Wong. All rights reserved.
//

import UIKit

class PanoViewController: UIViewController, UIToolbarDelegate {
    
    lazy private var toolbar: UIToolbar = {
        let tb = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 50))
        tb.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        tb.backgroundColor = UIColor.init(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.4)
        tb.isTranslucent = true
        tb.items = [closeButton, flexibleSpace, motionButton]
        tb.isHidden = true
        
        return tb
    }()
    
    lazy private var panoView: CTPanoramaView = {
        var pV = CTPanoramaView()
        return pV
    }()
    
    lazy private var compassView: CTPieSliceView = {
        let cV = CTPieSliceView()
        cV.isHidden = true
        return cV
    }()
    
    lazy private var motionButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(motionTypeTapped))
        return button
    }()
    
    lazy private var closeButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: nil)
        return button
    }()
    
    lazy private var flexibleSpace: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        return button
    }()
    
    //    lazy private var optionsButton: UIBarButtonItem = {
    //        let button = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: nil)
    //           return button
    //    }()
    
    var selectedGraph = Graph()
    
    private func commonInit(){
//        panoView.pursuitGraph = selectedGraph
//               print("Populate graph")
//        selectedGraph =  GraphData.manager.populateGraph()
//               print("Common Init")
        addSubviews()
        setConstraints()
        panoView.compass = compassView
        panoView.toolbar = toolbar
       
//        panoView.commonInit()
    }
    
    private func addSubviews(){
        view.addSubview(panoView)
        view.addSubview(compassView)
        view.addSubview(toolbar)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    
}

//MARK:- Panoramic Methods
extension PanoViewController{
    
    @objc private func motionTypeTapped(){
        if panoView.controlMethod == .touch{
            panoView.controlMethod = .motion
        }else{
            panoView.controlMethod = .touch
        }
        panoView.hudToggle = .hide
    }
    
    @objc private func dismiss(){
        dismiss(animated: true, completion: nil)
    }
}


//MARK:- Constraints
extension PanoViewController {
    
    private func setConstraints() {
        setPanoViewConstraints()
        setCompassPieConstraints()
        setToolbarConstraints()
    }
    
    private func setPanoViewConstraints(){
        self.panoView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            panoView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.panoView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.panoView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.panoView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
    }
    
    private func setCompassPieConstraints(){
        compassView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            compassView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            compassView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            compassView.heightAnchor.constraint(equalToConstant: 40),
            compassView.widthAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setToolbarConstraints(){
        self.toolbar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.toolbar.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            self.toolbar.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            self.toolbar.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
}
