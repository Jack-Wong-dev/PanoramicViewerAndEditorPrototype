import UIKit

@objc public enum TapSelection: Int {
    case reposition
    case selectNode
    case createNode
    case createReverseNode
    case none
}

class TourEditorVC: UIViewController, UIToolbarDelegate {
    
    lazy private var toolbar: UIToolbar = {
        let tb = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 40))
        tb.backgroundColor = UIColor.init(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.4)
        tb.isTranslucent = true
        tb.items = [cancelButton, flexibleSpace, doneButton]
        tb.isHidden = true
        return tb
    }()
    
    lazy var editorView: EditorView = {
        let editorV = EditorView(frame: view.frame, graph: selectedGraph, room: selectedRoom)
        return editorV
    }()
    
    lazy private var cancelButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
        button.isEnabled = false
        button.tintColor = .systemGreen
        return button
    }()
    
    lazy private var flexibleSpace: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        return button
    }()
    
    lazy private var doneButton: UIBarButtonItem = {
           let button = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
//           button.isEnabled = false
           button.tintColor = .systemGreen
           return button
    }()
    
    var fab = Floaty()
    
    private var selectedGraph = Graph()
    var selectedRoom = Room()
    
    init(graph: Graph, room: Room) {
        print("super init")
        self.selectedGraph = graph
        self.selectedRoom = room
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit(){
        print("common init")
        layoutFAB()
        addSubviews()
        setConstraints()
        editorView.toolbar = toolbar
        editorView.fab = fab
        //        fab.addDragging()
    }
    
    private func addSubviews(){
        view.addSubview(editorView)
        view.addSubview(toolbar)
        view.addSubview(fab)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
}

//MARK:- Panoramic Methods
extension TourEditorVC{
    
    @objc private func cancelButtonTapped(){
        editorView.hideToast()
        editorView.hudToggle = .hide
        editorView.tapPurpose = .selectNode
        editorView.controlMethod = .touch
        self.view.makeToast("Canceled")
    }
    
    @objc private func doneButtonTapped(){
        editorView.hideToast()
        editorView.hudToggle = .hide
        
        if editorView.controlMethod == .rotate {
            editorView.saveNewCameraPosition()
            editorView.controlMethod = .touch
        }
        
        editorView.tapPurpose = .selectNode
        self.view.makeToast("Finished")
    }
    
    @objc func exitEditor(){
        self.dismiss(animated: true, completion: nil)
    }
    
}

//MARK:- Constraints
extension TourEditorVC {
    
    private func setConstraints() {
        setPanoViewConstraints()
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
    
    
    private func setToolbarConstraints(){
        self.toolbar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.toolbar.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            self.toolbar.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            self.toolbar.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
}

extension TourEditorVC: FloatyDelegate {
    
    func layoutFAB() {
        fab.buttonColor = #colorLiteral(red: 0.4256733358, green: 0.5473166108, blue: 0.3936028183, alpha: 1)
        fab.hasShadow = true
        
        let addHotSpotItem = FloatyItem()
        addHotSpotItem.icon = UIImage(systemName: "mappin.and.ellipse")
        addHotSpotItem.buttonColor = .systemTeal
        addHotSpotItem.tintColor = #colorLiteral(red: 0.4256733358, green: 0.5473166108, blue: 0.3936028183, alpha: 1)
        addHotSpotItem.title = "Add Destination"
        addHotSpotItem.handler = { item in
             self.editorView.displayRoomList()
        }
                
        let rotateCameraItem = FloatyItem()
        rotateCameraItem.icon = UIImage(systemName: "camera.rotate")
        rotateCameraItem.buttonColor = .systemYellow
        rotateCameraItem.title = "Rotate Starting Angle"
        rotateCameraItem.handler = { item in
            self.editorView.controlMethod = .rotate
            self.editorView.hudToggle = .show
            
            self.view.makeToast("Pan to where you would like the starting angle to be", point: CGPoint(x: self.view.bounds.width/2, y: self.view.bounds.height/8), title: "Adjust Camera", image: UIImage(named: "funnyface"), completion: nil)
        }
        
        //Exit Editor Button
        let exitItem = FloatyItem()
        exitItem.icon = UIImage(systemName: "escape")
        exitItem.buttonColor = .systemRed
        exitItem.tintColor = .white
        exitItem.title = "Exit Editor"
        exitItem.handler = { item in
            self.dismiss(animated: true, completion: nil)
        }
        
        fab.addItem(item: addHotSpotItem)
        fab.addItem(item: rotateCameraItem)
        fab.addItem(item: exitItem)
        fab.fabDelegate = self
    }
    
    // MARK: - Floaty Delegate Methods
    func floatyWillOpen(_ floaty: Floaty) {
//        print("Floaty Will Open")
    }
    
    func floatyDidOpen(_ floaty: Floaty) {
//        print("Floaty Did Open")
    }
    
    func floatyWillClose(_ floaty: Floaty) {
//        print("Floaty Will Close")
    }
    
    func floatyDidClose(_ floaty: Floaty) {
//        print("Floaty Did Close")
    }
    
}

