//
//  CallToActionView.swift
//  CardGameAR
//
//  Created by Christopher Knapp on 24.06.23.
//

import Foundation
import SwiftUI
import Combine

struct CallToActionView: View {
    @State private var callToAction: String = ""
    @State private var currentGameState: GameState?
    private let gameStatePublisher: AnyPublisher<GameState, Never>
    private let updateGameStateAction: (GameState) -> Void
    
    init(gameState: AnyPublisher<GameState, Never>, updateGameStateAction: @escaping (GameState) -> Void) {
        self.gameStatePublisher = gameState
        self.updateGameStateAction = updateGameStateAction
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(callToAction)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
            if case let .inGame(state) = currentGameState {
                if case .waitForInteractionTypeSelection(let playerId, let cardValue) = state {
                    VStack {
                        buttonForInteractionType(.discard, playerId: playerId, cardValue: cardValue)
                        HStack {
                            buttonForInteractionType(.swapDrawnWithOwnCard, playerId: playerId, cardValue: cardValue)
                            buttonForInteractionType(.performAction(.anyAction), playerId: playerId, cardValue: cardValue)
                        }
                    }
                    .padding()
                    .frame(height: 200)
                }
            }
        }
        .onReceive(gameStatePublisher) { gameState in
            currentGameState = gameState
            handleGameStateChange(gameState)
        }
    }
    
    func buttonForInteractionType(_ interactionType: CardInteraction, playerId: Int, cardValue: Int) -> some View {
        var interactionType = interactionType
        var isPerformActionInteractionType = false
        let cardAction = CardAction(cardValue: cardValue)
        if case .performAction(_) = interactionType {
            isPerformActionInteractionType = true
            if let cardAction {
                interactionType = .performAction(cardAction)
            }
        }
        return Button() {
            updateGameStateAction(.inGame(.selectedInteractionType(playerId, interactionType, cardValue: cardValue)))
        } label: {
            Text(interactionType.displayText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isPerformActionInteractionType && cardAction == nil)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    
    private func handleGameStateChange(_ gameState: GameState) {
        switch gameState {
        case .preGame(let state):
            handlePreGameStateChange(state)
            break
        case .inGame(let state):
            handleInGameStateChange(state)
            break
        case .postGame:
            break
        }
    }
    
    private func handlePreGameStateChange(_ preGameState: GameState.PreGameState) {
        switch preGameState {
        case .loadingAssets:
            callToAction = "Loading Assets..."
            break
        case .placeDrawPile:
            callToAction = "Place Draw Pile"
            break
        case .setPlayerPositions:
            callToAction = "Set Player Positions and tap on \ndraw pile to deal the cards"
            break
        case .regardCards:
            callToAction = "Take a look at 2 of your cards and pass the device. Tap on draw pile to start the game"
        }
    }
    
    private func handleInGameStateChange(_ inGameState: GameState.InGameState) {
        switch inGameState {
        case .dealingCards:
            callToAction = "Dealing Cards..."
            break
        case .currentTurn(let playerId):
            callToAction = "Player \(playerId)'s turn!"
            break
        case .waitForInteractionTypeSelection(let playerId, _):
            callToAction = "Player \(playerId), select an interaction"
            break
        case .selectedInteractionType(let playerId, let interactionType, _):
            switch interactionType {
            case .performAction(let cardAction):
                switch cardAction {
                case .peek:
                    callToAction = "Peek\nLook at one of your hidden cards"
                    break
                case .spy:
                    callToAction = "Spy\nLook at one of your opponents cards"
                    break
                case .swap(let memorizedCard):
                    callToAction = "Swap\nExchange one of your cards with an opponent (\(memorizedCard != nil ? 1 : 0)/2)"
                    break
                case .anyAction:
                    callToAction = ""
                    break
                }
                break
            case .swapDrawnWithOwnCard:
                callToAction = "Player \(playerId), select the card to swap the drawn card with"
                break
            case .discard:
                callToAction =  "Player \(playerId), select matching covered cards\nand discard by tapping the drawn card"
                break
            }
        }
    }
}
