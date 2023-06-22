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
    private var playingCardModels: [PlayingCard: ModelEntity] = [:]
    
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
        Task {
            await preloadAllModelEntities()
            arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:))))
        }
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
    
    private func preloadAllModelEntities() async {
        let loadedModels: [PlayingCard: ModelEntity]? = try? await PlayingCard.allBlueCards()
            .reduceAsync([PlayingCard: ModelEntity]()) { partialResult, card in
                var partialResult = partialResult
                guard let modelEntity: ModelEntity = try? await loadModelAsync(named: card.assetName) else {
                    print("Failed to load model for Card")
                    throw CardGameError.failedToLoadModel
                }
                partialResult[card] = modelEntity
                return partialResult
            }
        guard let loadedModels else { return }
        self.playingCardModels = loadedModels
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
        let drawPileModel = DrawPile(with: cards, from: playingCardModels)
        arView.installGestures([.rotation, .translation], for: drawPileModel.entity)
        let parentAnchor = AnchorEntity(anchor: anchor)
        parentAnchor.addChild(drawPileModel.entity)
        arView.scene.addAnchor(parentAnchor)
    }
    
    // MARK: - Touch Interaction
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: arView)
        
        let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
        let hits = arView.hitTest(location, query: .nearest, mask: .all)
        if let drawPileEntity = hits.first?.entity {
            let animationDefinition1 = FromToByAnimation(
                to:
                    Transform(
                        rotation: drawPileEntity.transform.rotation * simd_quatf(angle: -.pi, axis: SIMD3<Float>(0, 0, 1)),
                        translation: [0.1, 0, 0]
                    ),
                bindTarget: .transform
            )
//            let animationDefinition2 = FromToByAnimation(to: Transform(translation: [0, 0, -0.1]), bindTarget: .anchorEntity("anchor").entity("blueBox").transform)
//            let animationGroupDefinition = AnimationGroup(group: [animationDefinition1, animationDefinition2])
//            let animationResource = try! AnimationResource.generate(with: animationGroupDefinition)
            let animationResource = try! AnimationResource.generate(with: animationDefinition1)
            drawPileEntity.playAnimation(animationResource, transitionDuration: 1, startsPaused: false)
        } else {
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
