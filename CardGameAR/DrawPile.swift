//
//  DrawPile.swift
//  CardGameAR
//
//  Created by Christopher Knapp on 21.06.23.
//

import Foundation
import ARKit
import RealityKit

// TODO: consider making this a subclass from `Entity` implementing `HasModel` and `HasCollision`
struct DrawPile {
    
    // MARK: - Constants
    
    static let identifier = "draw_pile"
    private static let modelScaleFactor: Float = 1
    
    // MARK: - Properties
    
    let entity: ModelEntity
    let discardPile: DiscardPile
    
    // MARK: - Life Cycle
    
    init(with cards: [PlayingCard], from playingCardModels: [PlayingCard: ModelEntity]) {
        entity = Self.createModelEntity(with: cards, from: playingCardModels)
        discardPile = DiscardPile(drawPile: entity, playingCard: cards[0], modelForCard: playingCardModels[cards[0]])
    }
    
    @MainActor
    func moveLastCardToDiscardPile() async {
        let animationDefinition1 = FromToByAnimation(
            to: Transform(
                rotation: discardPile.entity.transform.rotation * simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 0, 1)),
                translation: discardPile.entity.position(relativeTo: entity)
            ),
            bindTarget: .transform
        )
        let animationResource = try! AnimationResource.generate(with: animationDefinition1)
        
        guard let playingCard = entity.children.reversed().first else { return }
        
        await playingCard.playAnimationAsync(animationResource, transitionDuration: 1, startsPaused: false)
        entity.removeChild(playingCard, preservingWorldTransform: true)
        discardPile.setFirstCard(playingCard)
    }
    
    @MainActor
    func dealCards(cardsPerPlayer: Int, players: [Player]) async {
        for _ in 0..<cardsPerPlayer {
            for player in players {
                guard let playingCard = entity.children.reversed().first else { return }
                await moveCardToPlayer(playingCard: playingCard, player: player)
            }
        }
    }
    
    @MainActor
    private func moveCardToPlayer(playingCard: Entity, player: Player) async {
        // TODO: maybe lift the card slightly from the ground depending on the number of children
        let messyConcealedCardRotation = (player.transform.rotation
                                          * simd_quatf(ix: 1, iy: 0, iz: 0, r: 0) // card front facing to the plane
                                          * simd_quatf(angle: .random(in: -.pi...(.pi)), axis: SIMD3<Float>(0, 1, 0))) // messy appearance
        let animationDefinition1 = FromToByAnimation(
            to: Transform(
                rotation: messyConcealedCardRotation,
                translation: player.position(relativeTo: self.entity)
            ),
            bindTarget: .transform
        )
        let animationResource = try! AnimationResource.generate(with: animationDefinition1)
        
        await playingCard.playAnimationAsync(animationResource, transitionDuration: 1, startsPaused: false)
        entity.removeChild(playingCard, preservingWorldTransform: true)
        player.addChild(playingCard, preservingWorldTransform: true)
    }
    
    private static func createModelEntity(
        with cards: [PlayingCard],
        from playingCardModels: [PlayingCard: ModelEntity]
    ) -> ModelEntity {
        let parentEntity = ModelEntity()
        parentEntity.name = identifier
        cards.enumerated().forEach { [playingCardModels] numberOfCardInPile, card in
            guard let entity = playingCardModels[card]
            else {
                print("Model is null or error")
                return
            }
            let modelEntity = entity.clone(recursive: true)
            modelEntity.name = card.assetName
            let scaleFactor: Float = modelScaleFactor
            modelEntity.scale = SIMD3<Float>(scaleFactor, scaleFactor, scaleFactor)
            
            // move cards up with yOffset and move them slightly on x and z axis to appear a bit messy
            let xAndzMovingRange: ClosedRange<Float> = 0...0.0001
            let yOffset = Float(numberOfCardInPile) * (PlayingCard.thickness * 2)
            modelEntity.moveObject(x: Float.random(in: xAndzMovingRange), y: yOffset, z: Float.random(in: xAndzMovingRange))
            
            // make cards appear a bit messy by rotating
            let twoDegrees: Float = .pi / 90
            let randomRotationAngle = Float.random(in: -twoDegrees...twoDegrees)
            modelEntity.transform.rotation *= simd_quatf(angle: randomRotationAngle, axis: SIMD3<Float>(0, 1, 0))
            
            // rotate cards by 180° to show the back
            modelEntity.transform.rotation *= simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 0, 1))
            
            modelEntity.generateCollisionShapes(recursive: true)
            parentEntity.addChild(modelEntity)
        }
        return parentEntity
    }
}

struct DiscardPile {
    
    let entity: ModelEntity
    
    // params playingCard and modelForCard only for seeing something - didn't work yet though
    init(drawPile: Entity, playingCard: PlayingCard, modelForCard: Entity?) {
        let parentEntity = ModelEntity()
        parentEntity.generateCollisionShapes(recursive: true)
        // Get the transform of the draw pile's anchor
        guard let drawPileTransform = drawPile.anchor?.transform else {
            entity = parentEntity
            return
        }
        
        var discardPileTransformMatrix = drawPileTransform.matrix
        discardPileTransformMatrix.columns.3.x += 0.1
        
        let discardPileAnchor = ARAnchor(transform: discardPileTransformMatrix)
        let parentAnchor = AnchorEntity(anchor: discardPileAnchor)
        parentAnchor.addChild(parentEntity)
        self.entity = parentEntity
        
        
        // add any card to see something - not visible
        let modelEntity = entity.clone(recursive: true)
        modelEntity.name = playingCard.assetName
        modelEntity.generateCollisionShapes(recursive: true)
        parentEntity.addChild(modelEntity)
        
    }
    
    @MainActor
    func setFirstCard(_ card: Entity) {
        entity.addChild(card, preservingWorldTransform: true)
    }
    
}
