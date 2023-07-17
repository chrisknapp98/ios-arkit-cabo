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
                if case .waitForInteractionTypeSelection(let playerId) = state {
                    VStack {
                        buttonForInteractionType(playerId: playerId, .discard)
                        HStack {
                            buttonForInteractionType(playerId: playerId, .swapDrawnWithOwnCard)
                            buttonForInteractionType(playerId: playerId, .performAction)
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
    
    func buttonForInteractionType(playerId: Int, _ interactionType: CardInteraction) -> some View {
        Button() {
            updateGameStateAction(.inGame(.selectedInteractionType(playerId, interactionType)))
        } label: {
            Text(interactionType.displayText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.borderedProminent)
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
        case .waitForInteractionTypeSelection(let playerId):
            callToAction = "Player \(playerId), select an interaction"
            break
        case .selectedInteractionType(let playerId, let interactionType):
            switch interactionType {
            case .performAction:
                callToAction = "Player \(playerId), perform an action!"
                break
            case .swapDrawnWithOwnCard:
                callToAction = "Player \(playerId), select the card to swap the drawn card with"
                break
            case .discard:
                callToAction =  "Player \(playerId), select matching covered cards\nand discard by tapping the drawn card"
                break
            }
        case .interactWithDrawnCard(let playerId, interactionType: let interactionType):
//            callToAction = "Player \(playerId), select matching covered cards\nand discard by tapping the drawn card"
            break
        }
    }
}
