//
//  GameViewModel .swift
//  Personal Game
//
//  Created by David Santiago Jamaica Galvis on 8/14/25.
//

import Foundation
import SwiftUICore
import SwiftUI

class GameViewModel: ObservableObject {
    @Published var timeRemaining: Int = 120
    var gameTimer: Timer?
    @Published var gameOver = false
    @Published var lastAbilityUse: [GameViewModel.AbilityType: Date] = [:]
   
    let abilityCooldowns: [AbilityType: TimeInterval] = [
        .bomb: 3.0,
        .dash: 6.0
    ]
    
    let gridSize = CGSize(width: 20, height: 20)
    
    var playerCoveragePercentage: Double {
        let totalCells = Int(gridSize.width * gridSize.height)
        let playerColor = player.color

        let paintedCells = gridColors.flatMap { $0 }.filter { $0 == playerColor }.count

        return totalCells == 0 ? 0 : (Double(paintedCells) / Double(totalCells)) * 100
    }
    
    @Published var players: [Player] = []
    @Published var player = Player(position: CGPoint(x: 5, y: 5), color: .blue)
    @Published var gridColors: [[Color?]]
    @Published var bombs: [Bomb] = []

    let bombAbility = BombAbility()
    let dashAbility = DashAbility()

    @Published var selectedAbility: AbilityType = .bomb
    @Published var isDashActive = false

    enum AbilityType: String, CaseIterable, Identifiable {
        case bomb = "Bomb"
        case dash = "Dash"

        var id: String { self.rawValue }
    }

    init(settings: PlayerSettings) {

        self.gridColors = Array(
            repeating: Array(repeating: nil, count: Int(gridSize.height)),
            count: Int(gridSize.width)
        )

        self.player = Player(position: CGPoint(x: 5, y: 5), color: settings.color, emoji: settings.emoji)
        self.players = [self.player]
        self.selectedAbility = settings.ability
        
        DispatchQueue.main.async {
               self.startTimer()
           }
    }


    func colorAt(x: Int, y: Int) -> Color {
        if x < 0 || y < 0 || x >= Int(gridSize.width) || y >= Int(gridSize.height) {
            return Color.clear
        }
        return gridColors[x][y] ?? Color.clear
    }

    func movePlayer(_ direction: Direction) {
        let oldPosition = player.position

        if selectedAbility == .dash && isDashActive {
            dashAbility.dash(from: oldPosition, direction: direction, in: self)
            isDashActive = false
        } else {
            var newPosition = oldPosition
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
    
    func paintTilesAlongPath(from start: CGPoint, to end: CGPoint) {
        let steps = max(abs(Int(end.x - start.x)), abs(Int(end.y - start.y)))
        guard steps > 0 else { return }

        for i in 0...steps {
            let x = Int(round(start.x + CGFloat(i) * (end.x - start.x) / CGFloat(steps)))
            let y = Int(round(start.y + CGFloat(i) * (end.y - start.y) / CGFloat(steps)))
            if x >= 0 && y >= 0 && x < Int(gridSize.width) && y < Int(gridSize.height) {
                gridColors[x][y] = player.color
            }
        }
    }

    func plantBomb() {
        bombAbility.activate(for: player, in: self)
    }
    
    func canUseAbility(_ ability: AbilityType) -> Bool {
        guard let lastUsed = lastAbilityUse[ability],
              let cooldown = abilityCooldowns[ability] else {
            return true
        }
        return Date().timeIntervalSince(lastUsed) >= cooldown
    }

    func activateAbility() {
        guard canUseAbility(selectedAbility) else {
            print("Ablity \(selectedAbility.rawValue) is on cooldown")
            return
        }
        lastAbilityUse[selectedAbility] = Date()
        switch selectedAbility {
        case .bomb:
            plantBomb()
        case .dash:
            isDashActive = true
        }
    }
   

    func startTimer() {
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.gameTimer?.invalidate()
                self.gameOver = true
            }
        }
    }
}

