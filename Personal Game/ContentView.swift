//
//  contentView.swift
//  Personal Game
//
//  Created by David Santiago Jamaica Galvis on 7/30/25.
//

import Foundation
import SwiftUI

struct GameView : View {
    @StateObject private var viewModel = GameViewModel()
    let titleSize: CGFloat = 30
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                ForEach(0..<Int(viewModel.gridSize.width), id: \.self) { x in
                    ForEach(0..<Int(viewModel.gridSize.height), id: \.self) {
                        y in Rectangle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            .frame(width: titleSize, height: titleSize)
                            .position(x: CGFloat(x) * titleSize + titleSize / 2, y: CGFloat(y) * titleSize + titleSize / 2)
                    }
                }
                // Player
                Circle()
                    .fill(viewModel.player.color)
                    .frame(width: titleSize, height: titleSize)
                    .position(x: viewModel.player.position.x * titleSize + titleSize / 2, y: viewModel.player.position.y * titleSize + titleSize / 2)
                    .overlay(
                        viewModel.player.abilityActive ?
                        AnyView(Text("💣").offset(y: -25)) : AnyView(EmptyView())
                    )
            }
            .frame(width: titleSize * viewModel.gridSize.width, height: titleSize * viewModel.gridSize.height)
            .background(Color.black.opacity(0.05))
            .cornerRadius(10)
            
            VStack {
                HStack {
                    Spacer()
                    Button("⬆️") {
                        viewModel.movePlayer(.up)
                    }
                    Spacer()
                }
                HStack {
                    Button("⬅️") {
                        viewModel.movePlayer(.left)
                }
                    Spacer()
                    Button("➡️") {
                        viewModel.movePlayer(.right)
                }
            }
                HStack {
                    Spacer()
                    Button("⬇️") {
                        viewModel.movePlayer(.down)
                    }
                Spacer()
            }
        }
            .font(.largeTitle)
            
     //Ability
            Button(action: {
                viewModel.activateAbility()}) {
                    Text("Activate Ability 💣")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            Spacer()
            }
        .padding()
    }
}

#Preview {
    GameView()
}
