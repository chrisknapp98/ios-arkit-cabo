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
}
