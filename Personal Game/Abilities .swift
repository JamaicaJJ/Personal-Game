//
//  Abilities .swift
//  Personal Game
//
//  Created by David Santiago Jamaica Galvis on 8/22/25.
//

import Foundation
import SwiftUI

protocol Ability {
    var name: String { get }
    func activate(for player: Player, in viewModel: GameViewModel)
}

struct DashAbility: Ability {
    let name = "Dash"
    let dashDistance = 10

    func activate(for player: Player, in viewModel: GameViewModel) {
      
    }

    func dash(from position: CGPoint, direction: Direction, in viewModel: GameViewModel) {
        var newPosition = position 

        switch direction {
        case .up: newPosition.y -= CGFloat(dashDistance)
        case .down: newPosition.y += CGFloat(dashDistance)
        case .left: newPosition.x -= CGFloat(dashDistance)
        case .right: newPosition.x += CGFloat(dashDistance)
        }

        newPosition.x = min(max(0, newPosition.x), viewModel.gridSize.width - 1)
        newPosition.y = min(max(0, newPosition.y), viewModel.gridSize.height - 1)

        viewModel.player.position = newPosition
        viewModel.paintTilesAlongPath(from: position, to: newPosition)
    }
}
struct BombAbility: Ability {
    let name = "Bomb"

    func activate(for player: Player, in viewModel: GameViewModel) {
        let x = Int(player.position.x)
        let y = Int(player.position.y)
        let bomb = Bomb(x: CGFloat(x), y: CGFloat(y))
        viewModel.bombs.append(bomb)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            explode(bomb: bomb, color: player.color, in: viewModel)
        }
    }

    private func explode(bomb: Bomb, color: Color, in viewModel: GameViewModel) {
        let centerX = Int(bomb.x)
        let centerY = Int(bomb.y)
        let radius = 1

        for dx in -radius...radius {
            for dy in -radius...radius {
                let nx = centerX + dx
                let ny = centerY + dy

                if nx >= 0 && ny >= 0 &&
                    nx < Int(viewModel.gridSize.width) &&
                    ny < Int(viewModel.gridSize.height) {
                    viewModel.gridColors[nx][ny] = color
                }
            }
        }

        if let index = viewModel.bombs.firstIndex(of: bomb) {
            viewModel.bombs.remove(at: index)
        }
    }
}

