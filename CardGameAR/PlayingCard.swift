//
//  PlayingCard.swift
//  CardGameAR
//
//  Created by Christopher Knapp on 10.05.23.
//

enum PlayingCard: Hashable {
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
    static let width: Float = 0.063
    static let height: Float = 0.088
    static let prefix = "Playing_Card_"
    
    var assetName: String {
        switch self {
        case .blue(let type):
            let blue = "Blue"
            switch type {
            case .clubs(let value):
                return "\(Self.prefix)\(blue)_C_\(value.rawValue)"
            case .diamonds(let value):
                return "\(Self.prefix)\(blue)_D_\(value.rawValue)"
            case .hearts(let value):
                return "\(Self.prefix)\(blue)_H_\(value.rawValue)"
            case .spades(let value):
                return "\(Self.prefix)\(blue)_S_\(value.rawValue)"
            }
        case .red(let type):
            let red = "Red"
            switch type {
            case .clubs(let value):
                return "\(Self.prefix)\(red)_C_\(value.rawValue)"
            case .diamonds(let value):
                return "\(Self.prefix)\(red)_D_\(value.rawValue)"
            case .hearts(let value):
                return "\(Self.prefix)\(red)_H_\(value.rawValue)"
            case .spades(let value):
                return "\(Self.prefix)\(red)_S_\(value.rawValue)"
            }
        }
    }
}

extension PlayingCard {
    static func randomBlueCard() -> PlayingCard {
        guard let cardValue = PlayingCard.CardValue.allCases.randomElement()
        else { return PlayingCard.red(type: .hearts(value: .king)) }
        let randomNumber = Int.random(in: 0...3)
        if randomNumber == 0 {
            return PlayingCard.blue(type: .clubs(value: cardValue))
        } else if randomNumber == 1 {
            return PlayingCard.blue(type: .diamonds(value: cardValue))
        } else if randomNumber == 2 {
            return PlayingCard.blue(type: .hearts(value: cardValue))
        } else {
            return PlayingCard.blue(type: .spades(value: cardValue))
        }
    }
    
    static func allBlueCardsShuffled() -> [PlayingCard] {
        [
            PlayingCard.CardValue.allCases.map { PlayingCard.blue(type: .clubs(value: $0)) },
            PlayingCard.CardValue.allCases.map { PlayingCard.blue(type: .diamonds(value: $0)) },
            PlayingCard.CardValue.allCases.map { PlayingCard.blue(type: .hearts(value: $0)) },
            PlayingCard.CardValue.allCases.map { PlayingCard.blue(type: .spades(value: $0)) }
        ]
            .flatMap { $0 }
            .shuffled()
    }
}

extension PlayingCard {
    func getCardValue() -> Int {
        let numberString = String(assetName.split(separator: "_").last ?? "")
        return Int(numberString) ?? 0
    }
}
