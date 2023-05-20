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
    
    // MARK: - Constants
    
    private let modelFileName = "Playing_Cards_Standard"
    private let modelScaleFactor: Float = 0.01
    
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
        arView.environment.sceneUnderstanding.options.insert(.receivesLighting)
        runOcclusionConfiguration()
        arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:))))
    }
    
    private func runOcclusionConfiguration() {
        arView.environment.sceneUnderstanding.options.insert(.occlusion)
        let configuration = ARWorldTrackingConfiguration()
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth) // crashes on iPhone 11
        }
        // disabled because it's not applied although it seems to be available on iPhone 11
//        if ARConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
        configuration.frameSemantics.insert(.personSegmentationWithDepth)
//        }
        arView.session.run(configuration)
    }
    
    // MARK: - Object Placement
    
    func placeObject(named entityName: String, for anchor: ARAnchor) {
        guard let modelEntity = try? ModelEntity.loadModel(named: entityName)
        else {
           print("Couldn't load model for entity name \(entityName)")
            return
        }
        let scaleFactor: Float = modelScaleFactor
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
            let anchor = ARAnchor(name: modelFileName, transform: firstResult.worldTransform)
            arView.session.add(anchor: anchor)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } else {
            print("Object placement failed. Couldn't find a surface.")
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
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
        // Ready to add entities next?
        // Maybe automatically add the card deck in the middle of the table after a surface has been identified
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
