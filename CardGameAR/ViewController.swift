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
import SwiftUI

class ViewController: UIViewController {
    
    private var arView: ARView = ARView(frame: .zero)
    private var playingCardModels: [PlayingCard: ModelEntity] = [:]
    private let currentGameState = CurrentValueSubject<GameState, Never>(.preGame(.loadingAssets))
    private var drawPile: DrawPile?
    private var players: [Player] = []
    private var cancellables = Set<AnyCancellable>()
    
    private let cardsPerPlayer: Int = 4
    
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
//        arView.debugOptions = [.showAnchorOrigins, .showPhysics]
        arView.addCoaching()
        arView.environment.sceneUnderstanding.options.insert(.receivesLighting)
        runOcclusionConfiguration()
        addCallToActionView()
        Task {
            await preloadAllModelEntities()
            arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:))))
            updateGameState(.preGame(.placeDrawPile))
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
    
    private func addCallToActionView() {
        let hostingController = UIHostingController(rootView: CallToActionView(gameState: currentGameState.eraseToAnyPublisher()))
        hostingController.view.backgroundColor = .clear
        hostingController.view.isUserInteractionEnabled = false
        arView.addSubview(hostingController.view)
        hostingController.view?.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: arView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: arView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: arView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: arView.bottomAnchor)
        ])
    }
    
    @MainActor
    private func updateGameState(_ gameState: GameState) {
        currentGameState.send(gameState)
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
        self.drawPile = drawPileModel
    }
    
    // MARK: - Touch Interaction
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: arView)
        // TODO: switch case
        if case let .preGame(state) = currentGameState.value {
            if state == .setPlayerPositions {
                let hits = arView.hitTest(location, query: .nearest, mask: .all)
                if let playerEntity = hits.first?.entity as? Player {
                    playerEntity.removeFromParent()
                    players.remove(at: playerEntity.identity)
                    return
                } else if let cardEntity = hits.first?.entity, cardEntity.name.contains("Playing_Card") {
                    Task {
                        updateGameState(.inGame(.dealingCards))
                        await drawPile?.dealCards(cardsPerPlayer: cardsPerPlayer, players: players)
                    }
                    return
                }
            }
        }
        
        let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
        if let firstResult = results.first {
            if case let .preGame(state) = currentGameState.value {
                if state == .placeDrawPile {
                    let anchor = ARAnchor(name: DrawPile.identifier, transform: firstResult.worldTransform)
                    arView.session.add(anchor: anchor)
                } else if state == .setPlayerPositions {
                    let anchor = ARAnchor(name: "player_positions", transform: firstResult.worldTransform)
                    arView.session.add(anchor: anchor)
                }
            }
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
                Task {
                    await placeDrawPile(cards: PlayingCard.allBlueCards(), for: anchor)
                    updateGameState(.preGame(.setPlayerPositions))
                }
            } else if let anchorName = anchor.name, anchorName == "player_positions" {
                setPlayerPosition(for: anchor)
            }
        }
    }
    
    private func setPlayerPosition(for anchor: ARAnchor) {
        let entity = Player(identity: players.count)
        arView.installGestures([.translation], for: entity)
        let anchorEntity = AnchorEntity(anchor: anchor)
        anchorEntity.addChild(entity)
        arView.scene.addAnchor(anchorEntity)
        players.append(entity)
    }
}
