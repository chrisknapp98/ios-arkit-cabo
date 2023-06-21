//
//  DrawPile.swift
//  CardGameAR
//
//  Created by Christopher Knapp on 21.06.23.
//

import Foundation
import RealityKit

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
