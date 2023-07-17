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
        case waitForInteractionTypeSelection(_ playerId: Int)
        case selectedInteractionType(_ playerId: Int, _ interactionType: CardInteraction)
        case interactWithDrawnCard(_ playerId: Int, interactionType: CardInteraction)
    }
    
    case preGame(_ state: PreGameState)
    case inGame(_ state: InGameState)
    case postGame
}

enum CardInteraction: CaseIterable {
    case swapDrawnWithOwnCard
    case discard
    case performAction
    
    var displayText: String {
        switch self {
        case .discard:
            return "Discard one or multiple cards"
        case .performAction:
            return "Perform card action"
        case .swapDrawnWithOwnCard:
            return "Swap with covered card"
        }
    }
}
