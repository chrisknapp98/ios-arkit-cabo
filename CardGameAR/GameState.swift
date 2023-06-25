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
    
    case preGame(_ state: PreGameState)
    case inGame
    case postGame
}
