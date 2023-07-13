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
    private let gameStatePublisher: AnyPublisher<GameState, Never>
    
    init(gameState: AnyPublisher<GameState, Never>) {
        self.gameStatePublisher = gameState
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(callToAction)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding()
                .onReceive(gameStatePublisher) { gameState in
                    handleGameStateChange(gameState)
                }
            Spacer()
        }
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
        }
    }
}
