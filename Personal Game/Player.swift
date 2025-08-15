//
//  Player.swift
//  Personal Game
//
//  Created by David Santiago Jamaica Galvis on 8/14/25.
//

import Foundation
import SwiftUICore

enum Direction {
    case up , down , left , right
}

struct Player {
    var id: UUID = UUID()
    var position: CGPoint
    var color: Color
    var abilityActive: Bool = false
}
