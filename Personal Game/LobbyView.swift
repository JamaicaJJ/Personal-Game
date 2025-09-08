//
//  LobbyView.swift
//  Personal Game
//
//  Created by David Santiago Jamaica Galvis on 8/26/25.
//

import SwiftUI
import UIKit

struct RGBAColor: Codable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double
}

extension Color {
    init(_ rgba: RGBAColor) {
        self = Color(.sRGB, red: rgba.r, green: rgba.g, blue: rgba.b, opacity: rgba.a)
    }
    func toRGBA() -> RGBAColor {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return RGBAColor(r: r.double, g: g.double, b: b.double, a: a.double)
    }
}
private extension CGFloat { var double: Double { Double(self) } }

struct NetSettings: Codable {
    var emoji: String
    var ability: String
    var color: RGBAColor
}

struct LobbyView: View {
    @StateObject private var mpManager = MultipeerManager()

    @State private var selectedColor: Color = .blue
    @State private var selectedAbility: GameViewModel.AbilityType = .bomb
    @State private var selectedEmoji: String = "🤖"

    @State private var startGame = false

    @State private var remoteSettings: PlayerSettings? = nil

    let availableEmojis = ["🤖", "👾", "🎮", "🛡️", "🐉", "🧩"]

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
//Multiplayer Buttoms
                Text("Multiplayer").font(.headline)
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

                Group {
                    if mpManager.isConnected {
                        Text("Connected to: \(mpManager.connectedPeer?.displayName ?? "Unknown")")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    } else {
                        Text("Not Connected")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }

                Divider()

                // Player Settings
                Text("Player Settings").font(.title)

                ColorPicker("Select Color", selection: $selectedColor)
                    .padding()

                Picker("Select Ability", selection: $selectedAbility) {
                    ForEach(GameViewModel.AbilityType.allCases) { ability in
                        Text(ability.rawValue).tag(ability)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                Text("Select Your Emoji").font(.subheadline)
                HStack {
                    ForEach(availableEmojis, id: \.self) { emoji in
                        Text(emoji)
                            .font(.largeTitle)
                            .padding()
                            .background(selectedEmoji == emoji ? Color.gray.opacity(0.2) : Color.clear)
                            .clipShape(Circle())
                            .onTapGesture { selectedEmoji = emoji }
                    }
                }

                Spacer()

                // Start Game
                NavigationLink(
                    destination: GameView(
                        localPlayerSettings: PlayerSettings(color: selectedColor,
                                                            emoji: selectedEmoji,
                                                            ability: selectedAbility),
                        remotePlayerSettings: remoteSettings ?? PlayerSettings(color: .red, emoji: "👾", ability: .bomb),
                        mpManager: mpManager
                    ),
                    isActive: $startGame
                ) { EmptyView() }

                Button(action: { startGame = true }) {
                    Text("Start Game")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(startEnabled ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .disabled(!startEnabled)
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Paint Battle Lobby")
        }
        .onChange(of: mpManager.isConnected) { connected in
            if connected { sendMySettings() }
        }
        .onChange(of: selectedColor) { _ in if mpManager.isConnected { sendMySettings() } }
        .onChange(of: selectedAbility) { _ in if mpManager.isConnected { sendMySettings() } }
        .onChange(of: selectedEmoji) { _ in if mpManager.isConnected { sendMySettings() } }
        .onAppear {
            mpManager.onReceiveSettings = { settings in
                let ability = GameViewModel.AbilityType(rawValue: settings.ability) ?? .bomb
                let color = Color(settings.color)
                remoteSettings = PlayerSettings(color: color, emoji: settings.emoji, ability: ability)
            }
        }

    }

    private var startEnabled: Bool {
        mpManager.isConnected && remoteSettings != nil
    }

    private func sendMySettings() {
        let net = NetSettings(
            emoji: selectedEmoji,
            ability: selectedAbility.rawValue,
            color: selectedColor.toRGBA()
        )
        mpManager.sendSettings(net)
    }
}



