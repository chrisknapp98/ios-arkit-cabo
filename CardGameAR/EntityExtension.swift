//
//  EntityExtension.swift
//  CardGameAR
//
//  Created by Christopher Knapp on 13.07.23.
//

import Foundation
import RealityKit

extension Entity {
    func moveObject(x: Float, y: Float, z: Float) {
        let translation = SIMD3<Float>(x, y, z)
        var matrix = matrix_identity_float4x4
        matrix.columns.3.x = translation.x
        matrix.columns.3.y = translation.y
        matrix.columns.3.z = translation.z
        transform.matrix = matrix
    }
    
    func playAnimationAsync(_ animationResource: AnimationResource, transitionDuration: TimeInterval, startsPaused: Bool) async {
        playAnimation(animationResource, transitionDuration: transitionDuration, startsPaused: startsPaused)
        try? await Task.sleep(nanoseconds: UInt64((transitionDuration + 0.01) * 1_000_000_000))
    }
    
    func moveCardToPlayerWithOffset(player: Player) async {
        guard let card = children.reversed().first else { return }
        
        var targetTransform = self.convert(transform: transform, from : player)
        targetTransform.translation += SIMD3<Float>(0, Player.avatarHeight, 0)
        
        let animationDefinition1 = FromToByAnimation(
            to: targetTransform,
            bindTarget: .transform
        )
        let animationResource1 = try! AnimationResource.generate(with: animationDefinition1)
        
        await card.playAnimationAsync(animationResource1, transitionDuration: 1, startsPaused: false)
        
        // Swap the parents of the cards
        self.removeChild(card, preservingWorldTransform: true)
        player.addChild(card, preservingWorldTransform: true)
        player.setDrawnCard(card)
    }
}


