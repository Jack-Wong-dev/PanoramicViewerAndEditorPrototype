//  Created by Jack Wong on 1/27/20.
//  Copyright © 2020 Jack Wong. All rights reserved.
//

import UIKit

class PanoVC: UIViewController, UIToolbarDelegate {
    
    lazy private var toolbar: UIToolbar = {
        let tb = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 50))
//        tb.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
//        tb.backgroundColor = UIColor.init(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.4)
//        tb.isTranslucent = true
        tb.items = [closeButton, flexibleSpace, motionButton]
        tb.isHidden = true
        
        return tb
    }()
    
    lazy private var panoView: PanoView = {
        var pV = PanoView()
        return pV
    }()

    lazy private var motionButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(motionTypeTapped))
        button.tintColor = .systemGreen
        return button
    }()
    
    lazy private var closeButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(systemName: "xmark.square.fill"), style: UIBarButtonItem.Style.done, target: self, action: #selector(dismissVC))
        button.tintColor = .systemGreen
        return button
    }()
    
    lazy private var flexibleSpace: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        return button
    }()
    
    var selectedGraph = Graph()
    
    private func commonInit(){
        addSubviews()
        setConstraints()
        panoView.toolbar = toolbar
    }
    
    private func addSubviews(){
        view.addSubview(panoView)
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
extension PanoVC{
    @objc private func dismissVC() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func motionTypeTapped(){
        if panoView.controlMethod == .touch{
            panoView.controlMethod = .motion
        }else{
            panoView.controlMethod = .touch
        }
        panoView.hudToggle = .hide
    }
}


//MARK:- Constraints
extension PanoVC {
    
    private func setConstraints() {
        setPanoViewConstraints()
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
