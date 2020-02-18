import UIKit

class EditorViewController: UIViewController, UIToolbarDelegate {
    
    lazy private var toolbar: UIToolbar = {
        let tb = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 40))
        tb.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        tb.backgroundColor = UIColor.init(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.4)
        tb.isTranslucent = true
        tb.items = [cancelButton, flexibleSpace, optionsButton]

        return tb
    }()
    
    lazy private var editorView: EditorView = {
        let pV = EditorView()
        return pV
    }()
    
    lazy private var compassView: CTPieSliceView = {
        let cV = CTPieSliceView()
        cV.isHidden = true
        return cV
    }()
    
//    lazy private var closeButton: UIBarButtonItem = {
//        let button = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: nil)
//        return button
//    }()
    
    lazy private var cancelButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
        button.isEnabled = false
        button.tintColor = .clear
        return button
    }()
    
    lazy private var flexibleSpace: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        return button
    }()
    
    lazy private var optionsButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.edit, target: self, action: #selector(displayActionSheet(_:)))
           return button
    }()
 
    
    private func commonInit(){
        addSubviews()
        setConstraints()
        editorView.compass = compassView
        editorView.toolbar = toolbar
    }
    
    private func addSubviews(){
        view.addSubview(editorView)
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
extension EditorViewController{

    @objc private func motionTypeTapped(){
        if editorView.controlMethod == .touch{
            editorView.controlMethod = .motion
        }else{
            editorView.controlMethod = .touch
        }
        editorView.hudToggle = .hide
    }
    
    @objc private func cancelButtonTapped(){
        editorView.hideToast()
        editorView.tapToggle = .nodeSelection
        toolbar.items?[0].isEnabled = false
        toolbar.items?[0].tintColor = .clear
        editorView.makeToast("Cancelled")
    }
    
    @objc private func displayActionSheet(_ sender: UIBarButtonItem){

        let optionMenu = UIAlertController(title: nil, message: "Choose Option", preferredStyle: .alert)
         
         // 2
         let addAction = UIAlertAction(title: "Add Hotspot", style: .default)
         let saveAction = UIAlertAction(title: "Save", style: .default)
         
         // 3
         let exitAction = UIAlertAction(title: "Exit", style: .cancel)
         
         // 4
         optionMenu.addAction(addAction)
         optionMenu.addAction(saveAction)
         optionMenu.addAction(exitAction)
         
         // 5
//         optionMenu.popoverPresentationController?.barButtonItem = sender
        optionMenu.popoverPresentationController?.sourceView = self.view // works for both iPhone & iPad
//        optionMenu.popoverPresentationController?.sourceRect = CGRect(x: 100, y: 100, width: 200, height: 200)


//         optionMenu.popoverPresentationController?.sourceRect = self.view.bounds

         present(optionMenu, animated: true, completion: nil)
     }
}


//MARK:- Constraints
extension EditorViewController {
    
    private func setConstraints() {
        setPanoViewConstraints()
        setCompassPieConstraints()
        setToolbarConstraints()
    }
    
    private func setPanoViewConstraints(){
        self.editorView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            editorView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.editorView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.editorView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.editorView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
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
            toolbar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.toolbar.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            self.toolbar.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            self.toolbar.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
}

