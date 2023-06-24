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
        case .inGame:
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
        }
    }
}
