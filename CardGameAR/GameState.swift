//
//  GameState.swift
//  CardGameAR
//
//  Created by Christopher Knapp on 24.06.23.
//

import Foundation

enum GameState {
    
    enum PreGameState {
        case loadingAssets
        case placeDrawPile
    }
    
    case preGame(_ state: PreGameState)
    case inGame
    case postGame
}
