//
//  GameViewModel .swift
//  Personal Game
//
//  Created by David Santiago Jamaica Galvis on 8/14/25.
//

import Foundation

class GameViewModel: ObservableObject {
    @Published var player = Player(position: CGPoint(x: 5, y:5), color: .blue)
    
    let gridSize = CGSize(width: 10, height: 10)
    
    func movePlayer(_ direction: Direction) {
        var newPosition = player.position
        
        switch direction {
            
        case .up:
            newPosition.y -= 1
        case .down:
            newPosition.y += 1
        case .left:
            newPosition.x -= 1
        case .right:
            newPosition.x += 1
        }
        
        if newPosition.x >= 0 && newPosition.x < gridSize.width &&
            newPosition.y >= 0 && newPosition.y < gridSize.height {
            player.position = newPosition
        }
    }
    
    func activateAbility() {
        player.abilityActive = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.player.abilityActive = false
        }
    }
}
