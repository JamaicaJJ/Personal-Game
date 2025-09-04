//
//  Player.swift
//  Personal Game
//
//  Created by David Santiago Jamaica Galvis on 8/14/25.
//

import Foundation
import SwiftUICore



struct Player {
    var id: UUID = UUID()
    var position: CGPoint
    var color: Color
    var abilityActive: Bool = false
    var emoji: String = "🤖" 
}


enum Direction {
    case up , down , left , right
}


struct Bomb : Hashable {
    let x : CGFloat
    let y : CGFloat
}

struct PlayerSettings {
    let color: Color
    let emoji: String
    let ability: GameViewModel.AbilityType
}



