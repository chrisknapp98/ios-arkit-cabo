//
//  GameState.swift
//  CardGameAR
//
//  Created by Christopher Knapp on 24.06.23.
//

import Foundation
import class RealityKit.Entity

enum GameState: Equatable {
    
    enum PreGameState: Equatable {
        case loadingAssets
        case placeDrawPile
        case setPlayerPositions
        case regardCards
    }
    
    enum InGameState: Equatable {
        case dealingCards
        case currentTurn(_ playerId: Int)
        case waitForInteractionTypeSelection(_ playerId: Int, cardValue: Int)
        case selectedInteractionType(_ playerId: Int, _ interactionType: CardInteraction, cardValue: Int)
    }
    
    case preGame(_ state: PreGameState)
    case inGame(_ state: InGameState)
    case postGame
}

enum CardInteraction: Equatable {
    case swapDrawnWithOwnCard
    case discard
    case performAction(_ cardAction: CardAction)
    
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

enum CardAction: Equatable {
    case peek
    case spy
    case swap(memorizedCard: Entity?)
    case anyAction // for setting state from UI
    
    init?(cardValue: Int) {
        switch cardValue {
        case 7, 8:
            self = .peek
        case 9, 10:
            self = .spy
        case 11, 12:
            self = .swap(memorizedCard: nil)
        default:
            return nil
        }
    }
    
    var cardValues: [Int] {
        switch self {
        case .peek:
            return [7, 8]
        case .spy:
            return [9, 10]
        case .swap:
            return [11, 12]
        case .anyAction:
            return []
        }
    }
}
