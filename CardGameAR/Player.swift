//
//  Player.swift
//  CardGameAR
//
//  Created by Christopher Knapp on 25.06.23.
//

import Foundation
import RealityKit
import UIKit

class Player: Entity, HasModel, HasCollision {
    
    let identity: Int
    
    let playerIconWidth: Float = 0.05
    let playerIconHeight: Float = 0.0001
    let playerIconDepth: Float = 0.05
    
    private var avatar: ModelEntity
    private var currentlyDrawnCard: Entity?
    private var cardsToDiscard: [Entity] = []
    
    init(identity: Int) {
        self.identity = identity
        // Create a separate entity for the avatar
        avatar = ModelEntity()
        super.init()
        
        self.addChild(avatar)
        
        self.components[CollisionComponent.self] = CollisionComponent(shapes: [.generateBox(width: playerIconWidth, height: playerIconHeight, depth: playerIconDepth)])
        
        let mesh: MeshResource = .generatePlane(width: playerIconWidth, depth: playerIconDepth, cornerRadius: 8)
        
        var material = SimpleMaterial()
        if let image = UIImage(systemName: "person.circle.fill"),
           let cgImage = image.cgImage,
           let baseResource = try? TextureResource.generate(
            from: cgImage,
            options: TextureResource.CreateOptions(semantic: .color, mipmapsMode: .allocateAndGenerateAll)
           ) {
            material.color = SimpleMaterial.BaseColor(
                tint: .white.withAlphaComponent(0.999),
                texture: .init(baseResource)
            )
        }
        material.metallic = .float(1.0)
        material.roughness = .float(0.0)
        
        avatar.components[ModelComponent.self] = ModelComponent(mesh: mesh, materials: [material]) // Set the model on the avatar
        self.name = "Player-\(identity)"
        generateCollisionShapes(recursive: true)
    }
    
    @MainActor required init() {
        fatalError("init() has not been implemented")
    }
    
    @MainActor
    func arrangeCardsInGridForPlayer(player: Player) async {
        let cards = Array(player.children).filter { $0.name.contains(PlayingCard.prefix) }
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
            // Your existing quaternion, which is a 180 degree rotation around the x-axis
            let xAxisAlignment = simd_quatf(angle: Float.pi, axis: SIMD3(x: 1, y: 0, z: 0))
            
            // Get the player's rotation matrix and extract the y-axis vector
            let playerRotationMatrix = simd_float3x3(player.transform.rotation)
            let playerYAxisDirection = playerRotationMatrix.columns.1
            
            // Create a quaternion for the player's y-axis direction
            let playerYRotation = simd_quatf(from: SIMD3(x: 0, y: 1, z: 0), to: playerYAxisDirection)
            
            // Combine the two rotations by multiplying the quaternions
            let combineAlignment = xAxisAlignment * playerYRotation
            
            let alignedCardRotation = combineAlignment // card front facing to the plane
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
    
    func hideAvatar() {
        avatar.isEnabled = false
    }
    
    func setDrawnCard(_ card: Entity) {
        currentlyDrawnCard = card
    }
    
    func didInteractWithCard(_ card: Entity, discardPile: DiscardPile) async {
        if card != currentlyDrawnCard {
            cardsToDiscard.append(card)
            await turnCard(card)
        } else {
            if allMemorizedCardsMatchDrawnCard() {
                await discardMemorizedCards(to: discardPile)
            } else {
                for wronglyGuessedCard in cardsToDiscard {
                    await turnCard(wronglyGuessedCard)
                }
            }
            await discardDrawnCard(to: discardPile)
            cardsToDiscard = []
        }
    }
    
    private func turnCard(_ card: Entity) async {
        let animationDefinition1 = FromToByAnimation(
            to: Transform(
                rotation: card.transform.rotation * simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 0, 1)),
                translation: card.transform.translation
            ),
            bindTarget: .transform
        )
        let animationResource = try! AnimationResource.generate(with: animationDefinition1)
        
        await card.playAnimationAsync(animationResource, transitionDuration: 1, startsPaused: false)
    }
    
    private func allMemorizedCardsMatchDrawnCard() -> Bool {
        cardsToDiscard.allSatisfy { cardsToDiscard in
            cardsToDiscard.name.getPlayingCardValue() == currentlyDrawnCard?.name.getPlayingCardValue()
        }
    }
    
    private func discardMemorizedCards(to discardPile: DiscardPile) async {
        for card in cardsToDiscard {
            let transform = Transform(
                rotation: card.transform.rotation * simd_quatf(angle: .pi, axis: SIMD3<Float>(1, 0, 0)),
                translation: discardPile.entity.position(relativeTo: self)
            )
            await discardCard(card, with: transform, to: discardPile)
        }
    }
    
    private func discardDrawnCard(to discardPile: DiscardPile) async {
        guard let currentlyDrawnCard else { return }
        let transform = Transform(
            rotation: currentlyDrawnCard.transform.rotation,
            translation: discardPile.entity.position(relativeTo: self)
        )
        await discardCard(currentlyDrawnCard, with: transform, to: discardPile)
        self.currentlyDrawnCard = nil
    }
    
    private func discardCard(_ card: Entity, with transform: Transform, to discardPile: DiscardPile) async {
        let animationDefinition1 = FromToByAnimation(to: transform, bindTarget: .transform)
        let animationResource = try! AnimationResource.generate(with: animationDefinition1)
        
        await card.playAnimationAsync(animationResource, transitionDuration: 1, startsPaused: false)
        removeChild(card, preservingWorldTransform: true)
        discardPile.entity.addChild(card, preservingWorldTransform: true)
    }
    
}

extension String {
    func getPlayingCardValue() -> Int {
        let numberString = String(split(separator: "_").last ?? "")
        if numberString == "J" {
            return 11
        } else if numberString == "Q" {
            return 12
        } else if numberString == "K" {
            return 13
        } else if numberString == "A" {
            return 0
        }
        return Int(numberString) ?? 0
    }
}
