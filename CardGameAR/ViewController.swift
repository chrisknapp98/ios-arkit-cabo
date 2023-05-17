//
//  ViewController.swift
//  CardGameAR
//
//  Created by Christopher Knapp on 23.04.23.
//

import UIKit
import ARKit
import RealityKit

class ViewController: UIViewController {
    
    private var arView: ARView = ARView(frame: .zero)
    private let modelFileName = "Playing_Cards_Standard"
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(arView)
        arView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            arView.topAnchor.constraint(equalTo: view.topAnchor),
            arView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            arView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            arView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
        arView.session.delegate = self
        arView.addCoaching()
        
        arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:))))
    }
    
    // MARK: - Object Placement
    
    func placeObject(named entityName: String, for anchor: ARAnchor) {
        // TODO: no force unwrapping, also need to load the complete usdz file rather than just a single subcomponent
        let modelEntity = try! ModelEntity.loadModel(named: entityName)
        let scaleFactor: Float = 0.01 // Adjust this value to scale the object down
        modelEntity.scale = SIMD3<Float>(scaleFactor, scaleFactor, scaleFactor)
        
        modelEntity.generateCollisionShapes(recursive: true)
        arView.installGestures([.rotation, .translation], for: modelEntity)
        
        let anchorEntity = AnchorEntity(anchor: anchor)
        anchorEntity.addChild(modelEntity)
        arView.scene.addAnchor(anchorEntity)
    }
    
    // MARK: - Touch Interaction
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: arView)
        
        let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
        if let firstResult = results.first {
            let assetName = PlayingCards.blue(type: .spades(value: .ace)).assetName
            print("AssetName: \(assetName)")
            let anchor = ARAnchor(name: modelFileName, transform: firstResult.worldTransform)
            arView.session.add(anchor: anchor)
        } else {
            print("Object placement failed. Couldn't find a surface.")
        }
    }
}

// MARK: - ARView Coaching Overlay

extension ARView: ARCoachingOverlayViewDelegate {
    func addCoaching() {
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.delegate = self
        coachingOverlay.session = self.session
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.layer.position = CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height/2)
        coachingOverlay.goal = .horizontalPlane
        self.addSubview(coachingOverlay)
    }
    
    public func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        //Ready to add entities next?
    }
}

// MARK: - ARSessionDelegate

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let anchorName = anchor.name, anchorName == modelFileName {
                placeObject(named: anchorName, for: anchor)
            }
        }
    }
}
