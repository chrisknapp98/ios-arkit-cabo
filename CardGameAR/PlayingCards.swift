//
//  PlayingCards.swift
//  CardGameAR
//
//  Created by Christopher Knapp on 10.05.23.
//

enum PlayingCards {
    case blue(type: CardType)
    case red(type: CardType)
    
    enum CardType {
        case clubs(value: CardValue)
        case diamonds(value: CardValue)
        case hearts(value: CardValue)
        case spades(value: CardValue)
    }
    
    enum CardValue: String {
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
