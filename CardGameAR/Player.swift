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
    
    init(identity: Int) {
        self.identity = identity
        super.init()
        let x: Float = 0.05
        let y: Float = 0.0001
        let z: Float = 0.05
        self.components[CollisionComponent.self] = CollisionComponent(shapes: [.generateBox(width: x, height: y, depth: z)])
        
        
        let mesh: MeshResource = .generatePlane(width: x, depth: z, cornerRadius: 8)
        
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
    
}

struct PlayerAlt {
    let identity: Int
    let entity: ModelEntity
    
    init(identity: Int) {
        self.identity = identity
        let x: Float = 0.05
        let y: Float = 0.0001
        let z: Float = 0.05
        
        let mesh: MeshResource = .generatePlane(width: x, depth: z, cornerRadius: 8)
        
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
        
        entity = ModelEntity(mesh: mesh, materials: [material], collisionShape: .generateBox(width: x, height: y, depth: z), mass: 0)
        entity.name = "Player-\(identity)"
        entity.generateCollisionShapes(recursive: true)
    }
}
