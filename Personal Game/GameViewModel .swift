//
//  GameViewModel .swift
//  Personal Game
//
//  Created by David Santiago Jamaica Galvis on 8/14/25.
//

import SwiftUI
import Combine
import UIKit

final class GameViewModel: ObservableObject {

    // MARK: - Types
    enum AbilityType: String, CaseIterable, Identifiable, Codable {
        case bomb = "Bomb"
        case dash = "Dash"
        var id: String { rawValue }
    }

    // MARK: - Published State
    @Published var timeRemaining: Int = 120
    @Published var gameOver = false

    @Published var gridColors: [[Color?]]
    @Published var bombs: [Bomb] = []

    @Published var localPlayer: Player
    @Published var remotePlayer: Player?

    @Published var selectedAbility: AbilityType
    @Published var isDashActive = false

    // MARK: - Gameplay
    let gridSize = CGSize(width: 20, height: 20)
    private var gameTimer: Timer?

    var playerCoveragePercentage: Double {
        let total = Int(gridSize.width * gridSize.height)
        let painted = gridColors.flatMap { $0 }.filter { $0 == localPlayer.color }.count
        return total == 0 ? 0 : (Double(painted) / Double(total)) * 100.0
    }

    // Abilities
    private let bombAbility = BombAbility()
    private let dashAbility = DashAbility()

    // Cooldowns
    @Published var lastAbilityUse: [AbilityType: Date] = [:]
    let abilityCooldowns: [AbilityType: TimeInterval] = [.bomb: 3.0, .dash: 6.0]

    // Networking
    let mpManager: MultipeerManager

    // MARK: - Init
    init(localSettings: PlayerSettings, remoteSettings: PlayerSettings, mpManager: MultipeerManager) {
        self.mpManager = mpManager

        // grid
        self.gridColors = Array(
            repeating: Array(repeating: nil, count: Int(gridSize.height)),
            count: Int(gridSize.width)
        )

        // players
        self.localPlayer = Player(position: CGPoint(x: 5, y: 5),
                                  color: localSettings.color,
                                  emoji: localSettings.emoji,
                                  abilityActive: false)

        self.remotePlayer = Player(position: CGPoint(x: 15, y: 15),
                                   color: remoteSettings.color,
                                   emoji: remoteSettings.emoji,
                                   abilityActive: false)

        // ability
        self.selectedAbility = localSettings.ability

        // hook up networking callbacks
        wireMultipeerCallbacks()

        // start timer
        DispatchQueue.main.async { [weak self] in self?.startTimer() }
    }

    // MARK: - Networking bindings
    private func wireMultipeerCallbacks() {
        mpManager.onReceiveMove = { [weak self] direction in
            self?.applyRemoteMove(direction)
        }
        mpManager.onReceiveAbility = { [weak self] name in
            self?.applyRemoteAbility(named: name)
        }
    }

    // MARK: - Grid Helpers
    func colorAt(x: Int, y: Int) -> Color {
        guard x >= 0, y >= 0, x < Int(gridSize.width), y < Int(gridSize.height) else { return .clear }
        return gridColors[x][y] ?? .clear
    }

    private func isInBounds(_ pos: CGPoint) -> Bool {
        return pos.x >= 0 && pos.y >= 0 && pos.x < gridSize.width && pos.y < gridSize.height
    }

    private func paintTile(at position: CGPoint, color: Color) {
        let x = Int(position.x), y = Int(position.y)
        guard x >= 0, y >= 0, x < Int(gridSize.width), y < Int(gridSize.height) else { return }
        gridColors[x][y] = color
    }

    func paintTilesAlongPath(from start: CGPoint, to end: CGPoint, color: Color? = nil) {
        let steps = max(abs(Int(end.x - start.x)), abs(Int(end.y - start.y)))
        guard steps > 0 else { return }
        let useColor = color ?? localPlayer.color
        for i in 0...steps {
            let x = Int(round(start.x + CGFloat(i) * (end.x - start.x) / CGFloat(steps)))
            let y = Int(round(start.y + CGFloat(i) * (end.y - start.y) / CGFloat(steps)))
            guard x >= 0, y >= 0, x < Int(gridSize.width), y < Int(gridSize.height) else { continue }
            gridColors[x][y] = useColor
        }
    }

    // MARK: - Movement (Local)
    func handleMove(_ direction: Direction) {
        let old = localPlayer.position

        if selectedAbility == .dash && isDashActive {
            dashAbility.dash(from: old, direction: direction, in: self)
            isDashActive = false
        } else {
            var new = old
            switch direction {
            case .up:    new.y -= 1
            case .down:  new.y += 1
            case .left:  new.x -= 1
            case .right: new.x += 1
            }
            if isInBounds(new) {
                localPlayer.position = new
                paintTile(at: new, color: localPlayer.color)
            }
        }

        // tell peer
        mpManager.sendMove(direction)
    }

    // MARK: - Movement (Remote)
    private func applyRemoteMove(_ direction: Direction) {
        guard var rp = remotePlayer else { return }
        let old = rp.position

        // Note: remote dash is simulated on their device; we only get the resulting moves here.
        var new = old
        switch direction {
        case .up:    new.y -= 1
        case .down:  new.y += 1
        case .left:  new.x -= 1
        case .right: new.x += 1
        }
        if isInBounds(new) {
            rp.position = new
            paintTile(at: new, color: rp.color)
            remotePlayer = rp
        }
    }

    // MARK: - Abilities
    private func canUseAbility(_ ability: AbilityType) -> Bool {
        guard let last = lastAbilityUse[ability], let cd = abilityCooldowns[ability] else { return true }
        return Date().timeIntervalSince(last) >= cd
    }

    func activateAbility() {
        guard canUseAbility(selectedAbility) else { return }
        lastAbilityUse[selectedAbility] = Date()

        switch selectedAbility {
        case .bomb:
            plantBomb(at: localPlayer.position, color: localPlayer.color)
            mpManager.sendAbility(named: "bomb")
        case .dash:
            isDashActive = true
            // (Optionally inform peer; not required for correctness because moves are sent)
            mpManager.sendAbility(named: "dashStart")
        }
    }

    private func plantBomb(at position: CGPoint, color: Color) {
        let bomb = Bomb(x: position.x, y: position.y)
        bombs.append(bomb)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            let cx = Int(bomb.x), cy = Int(bomb.y), radius = 1
            for dx in -radius...radius {
                for dy in -radius...radius {
                    let nx = cx + dx, ny = cy + dy
                    guard nx >= 0, ny >= 0,
                          nx < Int(self.gridSize.width), ny < Int(self.gridSize.height) else { continue }
                    self.gridColors[nx][ny] = color
                }
            }
            if let idx = self.bombs.firstIndex(of: bomb) {
                self.bombs.remove(at: idx)
            }
        }
    }

    private func applyRemoteAbility(named name: String) {
        guard let rp = remotePlayer else { return }
        switch name {
        case "bomb":
            plantBomb(at: rp.position, color: rp.color)
        default:
            break
        }
    }

    // MARK: - Timer
    func startTimer() {
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if timeRemaining > 0 { timeRemaining -= 1 }
            else {
                gameTimer?.invalidate()
                gameOver = true
            }
        }
    }

    deinit {
        gameTimer?.invalidate()
    }
}

