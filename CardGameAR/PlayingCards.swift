//
//  PlayingCards.swift
//  CardGameAR
//
//  Created by Christopher Knapp on 10.05.23.
//

enum PlayingCards: Hashable {
    case blue(type: CardType)
    case red(type: CardType)
    
    enum CardType: Hashable {
        case clubs(value: CardValue)
        case diamonds(value: CardValue)
        case hearts(value: CardValue)
        case spades(value: CardValue)
    }
    
    enum CardValue: String, CaseIterable, Hashable {
        case two = "2"
        case three = "3"
        case four = "4"
        case five = "5"
        case six = "6"
        case seven = "7"
        case eight = "8"
        case nine = "9"
        case ten = "10"
        case jack = "J"
        case queen = "Q"
        case king = "K"
        case ace = "A"
    }
    
    static let thickness: Float = 0.00015
    
    var assetName: String {
        let prefix = "Playing_Card_"
        switch self {
        case .blue(let type):
            let blue = "Blue"
            switch type {
            case .clubs(let value):
                return "\(prefix)\(blue)_C_\(value.rawValue)"
            case .diamonds(let value):
                return "\(prefix)\(blue)_D_\(value.rawValue)"
            case .hearts(let value):
                return "\(prefix)\(blue)_H_\(value.rawValue)"
            case .spades(let value):
                return "\(prefix)\(blue)_S_\(value.rawValue)"
            }
        case .red(let type):
            let red = "Red"
            switch type {
            case .clubs(let value):
                return "\(prefix)\(red)_C_\(value.rawValue)"
            case .diamonds(let value):
                return "\(prefix)\(red)_D_\(value.rawValue)"
            case .hearts(let value):
                return "\(prefix)\(red)_H_\(value.rawValue)"
            case .spades(let value):
                return "\(prefix)\(red)_S_\(value.rawValue)"
            }
        }
    }
}

extension PlayingCards {
    static func randomBlueCard() -> PlayingCards {
        guard let cardValue = PlayingCards.CardValue.allCases.randomElement()
        else { return PlayingCards.red(type: .hearts(value: .king)) }
        let randomNumber = Int.random(in: 0...3)
        if randomNumber == 0 {
            return PlayingCards.blue(type: .clubs(value: cardValue))
        } else if randomNumber == 1 {
            return PlayingCards.blue(type: .diamonds(value: cardValue))
        } else if randomNumber == 2 {
            return PlayingCards.blue(type: .hearts(value: cardValue))
        } else {
            return PlayingCards.blue(type: .spades(value: cardValue))
        }
    }
    
    static func allBlueCards() -> [PlayingCards] {
        [
            PlayingCards.CardValue.allCases.map { PlayingCards.blue(type: .clubs(value: $0)) },
            PlayingCards.CardValue.allCases.map { PlayingCards.blue(type: .diamonds(value: $0)) },
            PlayingCards.CardValue.allCases.map { PlayingCards.blue(type: .hearts(value: $0)) },
            PlayingCards.CardValue.allCases.map { PlayingCards.blue(type: .spades(value: $0)) }
        ].flatMap { $0 }
    }
}
