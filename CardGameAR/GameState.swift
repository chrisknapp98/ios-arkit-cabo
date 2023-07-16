//
//  GameState.swift
//  CardGameAR
//
//  Created by Christopher Knapp on 24.06.23.
//

import Foundation

enum GameState: Equatable {
    
    enum PreGameState: Equatable {
        case loadingAssets
        case placeDrawPile
        case setPlayerPositions
    }
    
    enum InGameState: Equatable {
        case dealingCards
        case currentTurn(_ playerId: Int)
    }
    
    case preGame(_ state: PreGameState)
    case inGame(_ state: InGameState)
    case postGame
}
