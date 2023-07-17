//
//  DiscardPile.swift
//  CardGameAR
//
//  Created by Christopher Knapp on 15.07.23.
//

import Foundation
import RealityKit

struct DiscardPile {
    
    static let identifier = "discard_pile"
    let entity: ModelEntity
    
    var numberOfCardsInPile: Int {
        entity.children.filter { $0.name.contains(PlayingCard.prefix) }.count
    }
    
    init() {
        entity = ModelEntity()
        entity.name = Self.identifier
    }
    
}
