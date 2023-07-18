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
        playAnimation(animationResource, transitionDuration: 0.1, startsPaused: startsPaused)
        try? await Task.sleep(nanoseconds: UInt64((transitionDuration + 0.01) * 1_000_000_000))
    }
    
    func moveCardToPlayerWithOffset(player: Player) async {
        // TODO: maybe lift the card slightly from the ground depending on the number of children

        guard let playingCard = children.reversed().first else { return }

        
        var targetTransform = Transform(
               rotation: simd_quatf(angle: 0, axis: SIMD3<Float>(1, 0, 0)),
               translation: player.position(relativeTo: self)
           )

           var animationDefinition = FromToByAnimation(
               to: targetTransform,
               bindTarget: .transform
           )
           var animationResource = try! AnimationResource.generate(with: animationDefinition)

           await playingCard.playAnimationAsync(animationResource, transitionDuration: 1, startsPaused: false)
        
        
        // First move the card to player's location without animating
        removeChild(playingCard, preservingWorldTransform: true)
        player.addChild(playingCard, preservingWorldTransform: true)
        playingCard.transform.translation = player.transform.translation

        // Then animate from the player's location to the final location
        targetTransform = Transform(
            rotation: simd_quatf(angle: 0, axis: SIMD3<Float>(1, 0, 0)),
            translation: SIMD3<Float>(0, Player.avatarHeight, 0)
        )

        animationDefinition = FromToByAnimation(
            to: targetTransform,
            bindTarget: .transform
        )
        animationResource = try! AnimationResource.generate(with: animationDefinition)

        await playingCard.playAnimationAsync(animationResource, transitionDuration: 1, startsPaused: false)
        player.setDrawnCard(playingCard)
    }
    
    
}
