//
//  GameViewModel .swift
//  Personal Game
//
//  Created by David Santiago Jamaica Galvis on 8/14/25.
//

import Foundation
import SwiftUICore
import SwiftUI

struct Bomb: Hashable {
    let x: CGFloat
    let y: CGFloat
}

class GameViewModel: ObservableObject {
    let gridSize = CGSize(width: 20, height: 10)

    @Published var player = Player(position: CGPoint(x: 5, y: 5), color: .blue)
    @Published var gridColors: [[Color?]]
    @Published var bombs: [Bomb] = []

    init() {
        self.gridColors = Array(
            repeating: Array(repeating: nil, count: Int(gridSize.height)),
            count: Int(gridSize.width)
        )
    }

    func colorAt(x: Int, y: Int) -> Color {
        if x < 0 || y < 0 || x >= Int(gridSize.width) || y >= Int(gridSize.height) {
            return Color.clear
        }
        return gridColors[x][y] ?? Color.clear
    }

    func movePlayer(_ direction: Direction) {
        var newPosition = player.position
        switch direction {
        case .up: newPosition.y -= 1
        case .down: newPosition.y += 1
        case .left: newPosition.x -= 1
        case .right: newPosition.x += 1
        }

        if isInBounds(newPosition) {
            player.position = newPosition
            paintTile(at: newPosition)
        }
    }

    private func isInBounds(_ pos: CGPoint) -> Bool {
        return pos.x >= 0 && pos.y >= 0 &&
               pos.x < gridSize.width && pos.y < gridSize.height
    }

    private func paintTile(at position: CGPoint) {
        let x = Int(position.x)
        let y = Int(position.y)
        if x >= 0 && y >= 0 && x < Int(gridSize.width) && y < Int(gridSize.height) {
            gridColors[x][y] = player.color
        }
    }

    
    func plantBomb() {
        let x = Int(player.position.x)
        let y = Int(player.position.y)
        let bomb = Bomb(x: CGFloat(x), y: CGFloat(y))
        bombs.append(bomb)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.explodeBomb(bomb)
        }
    }

    private func explodeBomb(_ bomb: Bomb) {
        let centerX = Int(bomb.x)
        let centerY = Int(bomb.y)

        let explosionRadius = 1

        for dx in -explosionRadius...explosionRadius {
            for dy in -explosionRadius...explosionRadius {
                let nx = centerX + dx
                let ny = centerY + dy

                if nx >= 0 && ny >= 0 &&
                    nx < Int(gridSize.width) &&
                    ny < Int(gridSize.height) {
                    gridColors[nx][ny] = player.color
                }
            }
        }

        if let index = bombs.firstIndex(of: bomb) {
            bombs.remove(at: index)
        }
    }
}

