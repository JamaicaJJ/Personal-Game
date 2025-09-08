//
//  Player.swift
//  Personal Game
//
//  Created by David Santiago Jamaica Galvis on 8/14/25.
//

import Foundation
import SwiftUICore
import SwiftUI



struct Player: Identifiable, Hashable {
    let id: UUID = UUID()
    var position: CGPoint
    var color: Color
    var emoji: String
    var abilityActive: Bool = false
}

enum Direction: String, Codable, CaseIterable {
    case up
    case down
    case left
    case right
}


struct Bomb: Hashable {
    let x: CGFloat
    let y: CGFloat
}

struct PlayerSettings {
    let color: Color
    let emoji: String
    let ability: GameViewModel.AbilityType
}




