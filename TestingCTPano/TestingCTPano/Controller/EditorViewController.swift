
import UIKit

class EditorViewController: UIViewController {
    
    lazy private var panoView: CTPanoramaView = {
        let pV = CTPanoramaView()
        return pV
    }()
    
    lazy private var compassView: CTPieSliceView = {
        let cV = CTPieSliceView()
        return cV
    }()
    
    lazy private var motionButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.system)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.setTitle("Touch/Motion", for: .normal)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(motionTypeTapped),
                         for: .touchUpInside)
        return button
    }()
    
    private func commonInit(){
        addSubviews()
        setConstraints()
        panoView.compass = compassView
    }
    
    private func addSubviews(){
        view.addSubview(panoView)
        view.addSubview(compassView)
        view.addSubview(motionButton)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
}

//MARK:- Panoramic Methods
extension EditorViewController{
    
    @objc private func motionTypeTapped(){
        if panoView.controlMethod == .touch{
            panoView.controlMethod = .motion
        }else{
            panoView.controlMethod = .touch
        }
    }
}


//MARK:- Constraints
extension EditorViewController {
    
    private func setConstraints() {
        setPanoViewConstraints()
        setCompassPieConstraints()
        setMotionButtonConstraints()
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
            compassView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -20),
            compassView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            compassView.heightAnchor.constraint(equalToConstant: 40),
            compassView.widthAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setMotionButtonConstraints(){
        motionButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            motionButton.widthAnchor.constraint(equalToConstant: 100),
            motionButton.heightAnchor.constraint(equalToConstant: 40),
            motionButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 40),
            motionButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
        ])
    }
    
    
}

