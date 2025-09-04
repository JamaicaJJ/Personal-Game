//
//  contentView.swift
//  Personal Game
//
//  Created by David Santiago Jamaica Galvis on 7/30/25.
//

import Foundation
import SwiftUI


struct GameView: View {
    @State private var movementTimer: Timer?
    @StateObject private var viewModel: GameViewModel
    @Environment(\.dismiss) private var dissmiss
    
    
    
    init(playerSettings: PlayerSettings) {
        _viewModel = StateObject(wrappedValue: GameViewModel(settings: playerSettings))
    }
    func formattedTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    
    func movementButton(direction: Direction, systemImage: String) -> some View {
        Button(action: {
            viewModel.movePlayer(direction)
        }) {
            Image(systemName: systemImage)
                .resizable()
                .frame(width: 50, height: 50)
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.2)
                .onEnded { _ in
                    movementTimer?.invalidate()
                    movementTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                        viewModel.movePlayer(direction)
                    }
                }
        )
        .onLongPressGesture(minimumDuration: 0, pressing: { isPressing in
            if !isPressing {
                movementTimer?.invalidate()
            }
        }, perform: {})
    }
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            
            let columns = Int(viewModel.gridSize.width)
            let rows = Int(viewModel.gridSize.height)
            
            let tileWidth = screenWidth / CGFloat(columns)
            let tileHeight = screenHeight / CGFloat(rows)
            
            ZStack {
                // Grid
                ForEach(0..<columns, id: \.self) { x in
                    ForEach(0..<rows, id: \.self) { y in
                        Rectangle()
                            .fill(viewModel.colorAt(x: x, y: y))
                            .overlay(
                                Rectangle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                            )
                            .frame(width: tileWidth, height: tileHeight)
                            .position(
                                x: CGFloat(x) * tileWidth + tileWidth / 2,
                                y: CGFloat(y) * tileHeight + tileHeight / 2
                            )
                    }
                }
                
                // Bombs
                ForEach(viewModel.bombs, id: \.self) { bomb in
                    Text("💣")
                        .font(.system(size: min(tileWidth, tileHeight) * 0.8))
                        .position(
                            x: bomb.x * tileWidth + tileWidth / 2,
                            y: bomb.y * tileHeight + tileHeight / 2
                        )
                }
                
                // Player Emoji
                Text(viewModel.player.emoji)
                    .font(.system(size: min(tileWidth, tileHeight)))
                    .position(
                        x: viewModel.player.position.x * tileWidth + tileWidth / 2,
                        y: viewModel.player.position.y * tileHeight + tileHeight / 2
                    )
                
               //Timer Overlay (Top-Right)
                VStack {
                    HStack {
                        Spacer()
                        Text("Time: \(formattedTime(viewModel.timeRemaining))")
                            .padding(.top, -40)
                            .padding(.trailing, -200)
                        
                        Text("Coverage: \(String(format: "%.1f", viewModel.playerCoveragePercentage))%")
                              .font(.caption)
                              .foregroundColor(.green)
                       
                            .font(.title2)
                            .padding(8)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.top, 70)
                            .padding(.trailing, 10)
                    }
                    
                    Spacer()
                }
                
                // MARK: - Controls (Bottom)
                VStack {
                    Spacer()
                    HStack {
                        // Movement Buttons
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
                        
                        // Ability Button
                        Button(action: {
                            viewModel.activateAbility()
                        }) {
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
            .alert(isPresented: $viewModel.gameOver) {
                Alert(title: Text("Game Over"), message: Text("Time's up!"), dismissButton: .default(Text("OK")))
            }
        }
    }
}


#Preview {
    GameView(playerSettings: PlayerSettings(
        color: .blue,
        emoji: "🤖",
        ability: .bomb
    ))
}

