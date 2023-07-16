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
        try? await Task.sleep(nanoseconds: UInt64((0.1 + 0.01) * 1_000_000_000))
    }
    
    func moveCardToPlayerWithOffset(player: Player) async {
        // TODO: maybe lift the card slightly from the ground depending on the number of children
        
        guard let playingCard = children.reversed().first else { return }
        var targetTransformRotation = playingCard.transform.rotation
        if name == DrawPile.identifier {
            targetTransformRotation *= simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 0, 1))
        }
        
        // Get the player's rotation matrix and extract the z-axis vector
        let playerRotationMatrix = simd_float3x3(player.transform.rotation)
        let playerZAxisDirection = playerRotationMatrix.columns.2  // Use z-axis vector here
        
        // Create a quaternion for the player's z-axis direction
        let playerZRotation = simd_quatf(from: SIMD3(x: 0, y: 0, z: 1), to: playerZAxisDirection)  // Use z-axis here
        
        // Combine the two rotations by multiplying the quaternions
        let combineAlignment = playerZRotation
        
        let animationDefinition1 = FromToByAnimation(
            to: Transform(
                rotation: targetTransformRotation * combineAlignment,
                translation: player.position(relativeTo: self)
            ),
            bindTarget: .transform
        )
        let animationResource = try! AnimationResource.generate(with: animationDefinition1)
        
        await playingCard.playAnimationAsync(animationResource, transitionDuration: 1, startsPaused: false)
        removeChild(playingCard, preservingWorldTransform: true)
        player.addChild(playingCard, preservingWorldTransform: true)
        player.setDrawnCard(playingCard)
    }
    
}
