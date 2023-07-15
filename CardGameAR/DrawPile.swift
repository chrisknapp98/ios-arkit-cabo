//
//  DrawPile.swift
//  CardGameAR
//
//  Created by Christopher Knapp on 21.06.23.
//

import Foundation
import RealityKit

// TODO: consider making this a subclass from `Entity` implementing `HasModel` and `HasCollision`
struct DrawPile {
    
    // MARK: - Constants
    
    static let identifier = "draw_pile"
    private static let modelScaleFactor: Float = 1
    
    // MARK: - Properties
    
    let entity: ModelEntity
    
    // MARK: - Life Cycle
    
    init(with cards: [PlayingCard], from playingCardModels: [PlayingCard: ModelEntity]) {
        entity = Self.createModelEntity(with: cards, from: playingCardModels)
    }
    
    @MainActor
    func moveLastCardToDiscardPile(_ discardPile: DiscardPile) async {
        let transform = Transform(
            rotation: discardPile.entity.transform.rotation,
            translation: discardPile.entity.position(relativeTo: entity)
        )
        await moveLastCardToEntity(discardPile.entity, transform: transform)
    }
    
    @MainActor
    private func moveLastCardToEntity(_ targetEntity: Entity, transform: Transform) async {
        let animationDefinition1 = FromToByAnimation(to: transform, bindTarget: .transform)
        let animationResource = try! AnimationResource.generate(with: animationDefinition1)
        
        guard let playingCard = entity.children.reversed().first else { return }
        
        await playingCard.playAnimationAsync(animationResource, transitionDuration: 1, startsPaused: false)
        entity.removeChild(playingCard, preservingWorldTransform: true)
        targetEntity.addChild(playingCard, preservingWorldTransform: true)
    }
    
    @MainActor
    func dealCards(cardsPerPlayer: Int, players: [Player]) async {
        for _ in 0..<cardsPerPlayer {
            for player in players {
                guard let playingCard = entity.children.reversed().first else { return }
                await moveCardToPlayer(playingCard: playingCard, player: player)
            }
        }
        for player in players {
            await arrangeCardsInGridForPlayer(player: player)
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
    
    @MainActor
    private func arrangeCardsInGridForPlayer(player: Player) async {
        let cards = Array(player.children)
        let gridWidth = 2
        let gridHeight = cards.count / gridWidth
        let cardSpacing: Float = 0.1  // adjust this to set the spacing between the cards

        // Compute the total width and height of the grid
        let totalWidth = cardSpacing * Float(gridWidth - 1)
        let totalHeight = cardSpacing * Float(gridHeight - 1)

        // Define an offset for the grid
        let gridOffset = SIMD3<Float>(-totalWidth / 2, 0, -totalHeight)

        for (index, card) in cards.enumerated() {
            let row = index / gridWidth
            let column = index % gridWidth
            let offsetPosition = SIMD3<Float>(cardSpacing * Float(column), 0, -cardSpacing * Float(row))

            let alignedCardRotation = (player.transform.rotation * simd_quatf(ix: 1, iy: 0, iz: 0, r: 0)) // card front facing to the plane
            let animationDefinition1 = FromToByAnimation(
                to: Transform(
                    rotation: alignedCardRotation,
                    translation: player.transform.translation + offsetPosition + gridOffset
                ),
                bindTarget: .transform
            )
            let animationResource = try! AnimationResource.generate(with: animationDefinition1)

            await card.playAnimationAsync(animationResource, transitionDuration: 1, startsPaused: false)
        }
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
