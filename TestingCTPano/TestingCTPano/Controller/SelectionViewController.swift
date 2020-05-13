//
//  SelectionViewController.swift
//  TestingCTPano
//
//  Created by Jack Wong on 5/12/20.
//  Copyright © 2020 Jack Wong. All rights reserved.
//

import UIKit

class SelectionViewController: UIViewController {
    
    lazy private var selectView : SelectView = {
        let view = SelectView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.virtualTourButton.addTarget(self, action: #selector(goToTour), for: .touchUpInside)
        view.createTourButton.addTarget(self, action: #selector(goToEditor), for: .touchUpInside)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(selectView)
        setUpConstraints()
        print("Starting")
    }
    
    
    func startTour() {
        let graph = EditorGraphData.manager.populateGraph()
        let firstRoom = graph.getRoom(name: graph.firstRoomID!)
        let tourVC = TourEditorVC(graph: graph, room: firstRoom!)
        present(tourVC, animated: true, completion: nil)
    }
    
    //    func commonInit() {
    //
    //        print("starting common")
    //        let pursuitGraph =  GraphData.manager.populateGraph()
    //
    //        //Fetching the first room and image
    //
    //        guard let firstRoomID = pursuitGraph.firstRoomID else { return }
    //
    //        guard let firstRoom = pursuitGraph.floorPlan[firstRoomID] else { return }
    //
    //        guard let firstImageURL = firstRoom.imageURL else { return }
    //
    //        if var firstImage = UIImage(named: firstImageURL){
    //            firstImage = firstImage.resize(image: firstImage)
    //            self.imageDictionary[firstImageURL] = firstImage
    //        }
    //
    //
    //        //Trying to fetch the rest of the images
    //
    //        DispatchQueue.global(qos: .userInitiated).async {
    //            print("Fetching all the other images")
    //            for (_,room) in self.pursuitGraph.floorPlan where room.imageURL != self.pursuitGraph.firstRoomID{
    //                print("grabbing images")
    //                guard let imageURL = room.imageURL else { continue }
    //
    //                //If image already exists
    //                if self.imageDictionary[imageURL] == nil {
    //                    if var newRoomImage = UIImage(named: imageURL){
    //                        newRoomImage = newRoomImage.resize(image: newRoomImage)
    //                        self.imageDictionary[imageURL] = newRoomImage
    //                    }
    //                }
    //            }
    //        }
    //    }
    
    @objc private func goToTour() {
        let tourVC = PanoVC()
        tourVC.modalPresentationStyle = .fullScreen
        present(tourVC, animated: true, completion: nil)
    }
    
    @objc private func goToEditor() {
        let graph = EditorGraphData.manager.populateGraph()
        let firstRoom = graph.getRoom(name: graph.firstRoomID!)
        let editorVC = TourEditorVC(graph: graph, room: firstRoom!)
        editorVC.modalPresentationStyle = .fullScreen
        present(editorVC, animated: true, completion: nil)
    }
}

//Constraints
extension SelectionViewController {
    private func setUpConstraints() {
        NSLayoutConstraint.activate([
            selectView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            selectView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            selectView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            selectView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
}
