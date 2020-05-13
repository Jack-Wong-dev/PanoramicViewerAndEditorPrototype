import UIKit

class SelectView: UIView {
    
    lazy var virtualTourButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("View Tour", for: .normal)
        button.setTitleColor(.systemBackground, for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 25.0
        return button
    }()
    
    lazy var createTourButton: UIButton = {
          let button = UIButton()
          button.translatesAutoresizingMaskIntoConstraints = false
          button.setTitle("Create Tour", for: .normal)
          button.setTitleColor(.systemBackground, for: .normal)
          button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
          button.titleLabel?.adjustsFontForContentSizeCategory = true
          button.backgroundColor = .systemGreen
          button.layer.cornerRadius = 25.0
          return button
    }()
    
    lazy var labelContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        return view
    }()
    
    lazy var vStackView: UIStackView = {
        let vStack = UIStackView(arrangedSubviews: [virtualTourButton, createTourButton])
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.alignment = .center
        vStack.distribution = .fillEqually
        vStack.axis = .vertical
        vStack.spacing = 10
        return vStack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        setLabelContainerViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setLabelContainerViews(){
        labelContainerView.addSubview(vStackView)
        
        addSubview(labelContainerView)
        
        NSLayoutConstraint.activate([
            
            labelContainerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            labelContainerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            labelContainerView.heightAnchor.constraint(equalTo: heightAnchor,multiplier: 0.50),
            labelContainerView.widthAnchor.constraint(equalTo: widthAnchor,multiplier: 0.50),
            
            vStackView.centerYAnchor.constraint(equalTo: labelContainerView.centerYAnchor),
            vStackView.centerXAnchor.constraint(equalTo: labelContainerView.centerXAnchor),
            vStackView.heightAnchor.constraint(equalTo: labelContainerView.heightAnchor),
            vStackView.widthAnchor.constraint(equalTo: labelContainerView.widthAnchor),
            
            virtualTourButton.widthAnchor.constraint(equalTo: vStackView.widthAnchor),
            createTourButton.widthAnchor.constraint(equalTo: vStackView.widthAnchor)
            
        ])
    }
    
    
}
