//
//  LobbyView.swift
//  Personal Game
//
//  Created by David Santiago Jamaica Galvis on 8/26/25.
//

import Foundation
import SwiftUI
import MultipeerConnectivity

struct LobbyView: View {
    @StateObject private var mpManager = MultipeerManager()

    @State private var selectedColor: Color = .blue
    @State private var selectedAbility: GameViewModel.AbilityType = .bomb
    @State private var selectedEmoji: String = "🤖"
    @State private var startGame = false

    let availableEmojis = ["🤖", "👾", "🎮", "🛡️"]

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // MARK: - Multiplayer Controls
                Text("Multiplayer")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    Button("Host Game") {
                        mpManager.startHosting()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())

                    Button("Join Game") {
                        mpManager.joinGame()
                    }
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }

                if mpManager.isConnected {
                    Text("Connected to: \(mpManager.connectedPeer?.displayName ?? "Unknown")")
                        .font(.subheadline)
                        .foregroundColor(.green)
                } else {
                    Text("Not Connected")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }

                Divider()

                // MARK: - Player Settings
                Text("Player Settings")
                    .font(.title)

                ColorPicker("Select Color", selection: $selectedColor)
                    .padding()

                Picker("Select Ability", selection: $selectedAbility) {
                    ForEach(GameViewModel.AbilityType.allCases) { ability in
                        Text(ability.rawValue).tag(ability)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                Text("Select Your Emoji")
                    .font(.subheadline)

                HStack {
                    ForEach(availableEmojis, id: \.self) { emoji in
                        Text(emoji)
                            .font(.largeTitle)
                            .padding()
                            .background(selectedEmoji == emoji ? Color.gray.opacity(0.3) : Color.clear)
                            .clipShape(Circle())
                            .onTapGesture {
                                selectedEmoji = emoji
                            }
                    }
                }

                Spacer()

                // MARK: - Start Game Button
                NavigationLink(
                    destination: GameView(
                        playerSettings: PlayerSettings(color: selectedColor, emoji: selectedEmoji, ability: selectedAbility)
                        // You can pass mpManager here if GameView needs it
                    ),
                    isActive: $startGame
                ) {
                    Button("Start Game") {
                        startGame = true
                    }
                    .padding()
                    .background(mpManager.isConnected ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
                .disabled(!mpManager.isConnected)

                Spacer()
            }
            .padding()
        }
    }
}


