//
//  ViewController.swift
//  CardGameAR
//
//  Created by Christopher Knapp on 23.04.23.
//

import UIKit
import ARKit
import RealityKit
import Combine

class ViewController: UIViewController {
    
    private var arView: ARView = ARView(frame: .zero)
    
    // MARK: - Constants
    
    private let drawPile = "draw_pile"
    private let modelScaleFactor: Float = 1
    private var playingCardModels: [PlayingCards: Task<ModelEntity, Error>] = [:]
    
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
        preloadAllModelEntities()
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
    
    private func preloadAllModelEntities() {
        PlayingCards.allBlueCards().forEach { card in
            let task: Task<ModelEntity, Error> = Task {
                try await loadModelAsync(named: card.assetName)
            }
            playingCardModels[card] = task
        }
        
//        playingCardModels.keys.forEach { card in
//            Task { try await playingCardModels[card]?.value }
//        }
    }
    
    private func loadModelAsync(named entityName: String) async throws -> ModelEntity {
        return try await withCheckedThrowingContinuation { continuation in
            ModelEntity.loadModelAsync(named: entityName)
                .subscribe(
                    Subscribers.Sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .failure(let error):
                                print("Couldn't load model for entity name \(entityName)")
                                continuation.resume(throwing: error)
                                break
                            case .finished:
                                break
                            }
                        }, receiveValue: { modelEntity in
                            continuation.resume(returning: modelEntity)
                        }
                    )
                )
        }
    }
    
    // MARK: - Object Placement
    
    private func placeObject(named entityName: String, for anchor: ARAnchor, numberOfCardInPile: Int) async {
        guard let modelEntity = try? await loadModelAsync(named: entityName)
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
        self.arView.scene.addAnchor(anchorEntity)
    }
    
    private func placePreloadedModel(card: PlayingCards, for anchor: ARAnchor) async {
        guard let entity = try? await playingCardModels[card]?.value
        else {
            print("Model is null or error")
            return
        }
        let modelEntity = entity.clone(recursive: true)
        let scaleFactor: Float = modelScaleFactor
        modelEntity.scale = SIMD3<Float>(scaleFactor, scaleFactor, scaleFactor)
        modelEntity.generateCollisionShapes(recursive: true)
        arView.installGestures([.rotation, .translation], for: modelEntity)
        let anchorEntity = AnchorEntity(anchor: anchor)
        anchorEntity.addChild(modelEntity)
        self.arView.scene.addAnchor(anchorEntity)
    }
    
    private func placeDrawPile(cards: [PlayingCards], for anchor: ARAnchor) async {
        await cards.enumerated().forEachAsync { [playingCardModels] numberOfCardInPile, card in
            guard let entity = try? await playingCardModels[card]?.value
            else {
                print("Model is null or error")
                return
            }
            let modelEntity = entity.clone(recursive: true)
            let scaleFactor: Float = modelScaleFactor
            modelEntity.scale = SIMD3<Float>(scaleFactor, scaleFactor, scaleFactor)
            
            // move cards up with yOffset and move them slightly on x and z axis to appear a bit messy
            let xAndzMovingRange: ClosedRange<Float> = 0...0.0001
            let yOffset = Float(numberOfCardInPile) * (PlayingCards.thickness * 2)
            modelEntity.moveObject(x: Float.random(in: xAndzMovingRange), y: yOffset, z: Float.random(in: xAndzMovingRange))
            
            // make cards appear a bit messy by rotating
            let twoDegrees: Float = .pi / 90
            let randomRotationAngle = Float.random(in: -twoDegrees...twoDegrees)
            modelEntity.transform.rotation *= simd_quatf(angle: randomRotationAngle, axis: SIMD3<Float>(0, 1, 0))
            
            // rotate cards by 180° to show the back
            modelEntity.transform.rotation *= simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 0, 1))
            
            modelEntity.generateCollisionShapes(recursive: true)
            arView.installGestures([.rotation, .translation], for: modelEntity)
            let anchorEntity = AnchorEntity(anchor: anchor)
            anchorEntity.addChild(modelEntity)
            self.arView.scene.addAnchor(anchorEntity)
        }
    }
    
    // MARK: - Touch Interaction
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: arView)
        
        let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
        if let firstResult = results.first {
            let anchor = ARAnchor(name: drawPile, transform: firstResult.worldTransform)
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
            if let anchorName = anchor.name, anchorName == drawPile {
                Task { await placeDrawPile(cards: PlayingCards.allBlueCards(), for: anchor) }
            }
        }
    }
}

// MARK: - ModelEntity Extension

extension ModelEntity {
    func moveObject(x: Float, y: Float, z: Float) {
        let translation = SIMD3<Float>(x, y, z)
        var matrix = matrix_identity_float4x4
        matrix.columns.3.x = translation.x
        matrix.columns.3.y = translation.y
        matrix.columns.3.z = translation.z
        transform.matrix = matrix
    }
}
