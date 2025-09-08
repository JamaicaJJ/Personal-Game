//
//  contentView.swift
//  Personal Game
//
//  Created by David Santiago Jamaica Galvis on 7/30/25.
//

import SwiftUI

struct GameView: View {
    @StateObject private var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    // Long-press repeat
    @State private var movementTimer: Timer?

    // Init
    init(localPlayerSettings: PlayerSettings,
         remotePlayerSettings: PlayerSettings,
         mpManager: MultipeerManager)
    {
        _viewModel = StateObject(wrappedValue:
            GameViewModel(localSettings: localPlayerSettings,
                          remoteSettings: remotePlayerSettings,
                          mpManager: mpManager)
        )
    }

    // Time
    private func formattedTime(_ totalSeconds: Int) -> String {
        let m = totalSeconds / 60
        let s = totalSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func movementButton(direction: Direction, systemImage: String) -> some View {
        Button(action: { viewModel.handleMove(direction) }) {
            Image(systemName: systemImage)
                .resizable()
                .frame(width: 50, height: 50)
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.2).onEnded { _ in
                movementTimer?.invalidate()
                movementTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                    viewModel.handleMove(direction)
                }
            }
        )
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            if !pressing { movementTimer?.invalidate() }
        }, perform: {})
    }

    var body: some View {
        GeometryReader { geo in
            let columns = Int(viewModel.gridSize.width)
            let rows = Int(viewModel.gridSize.height)
            let tileW = geo.size.width / CGFloat(columns)
            let tileH = geo.size.height / CGFloat(rows)

            ZStack {
                // Grid
                ForEach(0..<columns, id: \.self) { x in
                    ForEach(0..<rows, id: \.self) { y in
                        Rectangle()
                            .fill(viewModel.colorAt(x: x, y: y))
                            .overlay(
                                Rectangle().stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                            )
                            .frame(width: tileW, height: tileH)
                            .position(x: CGFloat(x) * tileW + tileW / 2,
                                      y: CGFloat(y) * tileH + tileH / 2)
                    }
                }

                // Bombs
                ForEach(viewModel.bombs, id: \.self) { bomb in
                    Text("💣")
                        .font(.system(size: min(tileW, tileH) * 0.8))
                        .position(x: bomb.x * tileW + tileW / 2,
                                  y: bomb.y * tileH + tileH / 2)
                }

                // Players
                Text(viewModel.localPlayer.emoji)
                    .font(.system(size: min(tileW, tileH)))
                    .position(x: viewModel.localPlayer.position.x * tileW + tileW / 2,
                              y: viewModel.localPlayer.position.y * tileH + tileH / 2)

                if let rp = viewModel.remotePlayer {
                    Text(rp.emoji)
                        .font(.system(size: min(tileW, tileH)))
                        .position(x: rp.position.x * tileW + tileW / 2,
                                  y: rp.position.y * tileH + tileH / 2)
                }

           
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("Time: \(formattedTime(viewModel.timeRemaining))")
                                .font(.headline)
                                .padding(8)
                                .background(Color.black.opacity(0.6))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            Text("Coverage: \(String(format: "%.1f", viewModel.playerCoveragePercentage))%")
                                .font(.headline)
                                .padding(8)
                                .background(Color.black.opacity(0.6))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(.top, 20)
                        .padding(.trailing, 16)
                    }
                    Spacer()
                }

                // Controls
                VStack {
                    Spacer()
                    HStack {
                        // Movement
                        VStack(spacing: 8) {
                            movementButton(direction: .up, systemImage: "arrow.up.circle.fill")
                            HStack(spacing: 8) {
                                movementButton(direction: .left, systemImage: "arrow.left.circle.fill")
                                movementButton(direction: .right, systemImage: "arrow.right.circle.fill")
                            }
                            movementButton(direction: .down, systemImage: "arrow.down.circle.fill")
                        }
                        .foregroundColor(.blue)
                        .padding(.leading, 20)

                        Spacer()

                        // Ability
                        Button(action: { viewModel.activateAbility() }) {
                            Text(viewModel.selectedAbility == .bomb ? "💣" : "⚡️")
                                .font(.title)
                                .padding(20)
                                .background(viewModel.selectedAbility == .bomb ? Color.red : Color.orange)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.bottom, 30)
                }
            }
            .edgesIgnoringSafeArea(.all)
            .alert("Game Over", isPresented: $viewModel.gameOver) {
                Button("OK") { dismiss() }
            } message: {
                Text("Time’s up!")
            }
        }
    }
}


