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
    
    init(identity: Int) {
        self.identity = identity
        super.init()
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
        
        self.components[ModelComponent.self] = ModelComponent(mesh: mesh, materials: [material])
        self.name = "Player-\(identity)"
        generateCollisionShapes(recursive: true)
    }
    
    @MainActor required init() {
        fatalError("init() has not been implemented")
    }
    
    func distributeCardsEvenly() async {
//        for playingCard in children {
//
//        }
    }
    
}
