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
    private var playingCardModels: [PlayingCard: Task<ModelEntity, Error>] = [:]
    
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
        PlayingCard.allBlueCards().forEach { card in
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
    
    private func placeDrawPile(cards: [PlayingCard], for anchor: ARAnchor) async {
        let loadedModels: [PlayingCard: ModelEntity]? = try? await cards
            .reduceAsync([PlayingCard: ModelEntity]()) { [playingCardModels] partialResult, card in
                var partialResult = partialResult
                guard let modelEntity: ModelEntity = try? await playingCardModels[card]?.value else {
                    print("Failed to load model for Card")
                    throw CardGameError.failedToLoadModel
                }
                partialResult[card] = modelEntity
                return partialResult
            }
        guard let loadedModels else { return }
        let drawPileModel = DrawPile(with: cards, from: loadedModels)
        arView.installGestures([.rotation, .translation], for: drawPileModel.entity)
        let parentAnchor = AnchorEntity(anchor: anchor)
        parentAnchor.addChild(drawPileModel.entity)
        arView.scene.addAnchor(parentAnchor)
    }
    
    // MARK: - Touch Interaction
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: arView)
        
        let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
        if let firstResult = results.first {
            let anchor = ARAnchor(name: DrawPile.identifier, transform: firstResult.worldTransform)
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
            // TODO: introduce some sort of game state to match the expected anchorName
            if let anchorName = anchor.name, anchorName == DrawPile.identifier {
                Task { await placeDrawPile(cards: PlayingCard.allBlueCards(), for: anchor) }
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
