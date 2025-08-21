//
//  contentView.swift
//  Personal Game
//
//  Created by David Santiago Jamaica Galvis on 7/30/25.
//

import Foundation
import SwiftUI

struct GameView: View {
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height

            let columns = Int(viewModel.gridSize.width)
            let rows = Int(viewModel.gridSize.height)

            let tileWidth = screenWidth / CGFloat(columns)
            let tileHeight = screenHeight / CGFloat(rows)

            ZStack {
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

              
                ForEach(viewModel.bombs, id: \.self) { bomb in
                    Text("💣")
                        .font(.system(size: min(tileWidth, tileHeight) * 0.8))
                        .position(
                            x: bomb.x * tileWidth + tileWidth / 2,
                            y: bomb.y * tileHeight + tileHeight / 2
                        )
                }

                
                Text("🤖")
                    .font(.system(size: min(tileWidth, tileHeight)))
                    .position(
                        x: viewModel.player.position.x * tileWidth + tileWidth / 2,
                        y: viewModel.player.position.y * tileHeight + tileHeight / 2
                    )

           
                VStack {
                    Spacer()
                    HStack {
                        VStack(spacing: 8) {
                            Button(action: { viewModel.movePlayer(.up) }) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                            }
                            HStack(spacing: 8) {
                                Button(action: { viewModel.movePlayer(.left) }) {
                                    Image(systemName: "arrow.left.circle.fill")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                }
                                Button(action: { viewModel.movePlayer(.right) }) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                }
                            }
                            Button(action: { viewModel.movePlayer(.down) }) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                            }
                        }
                        .foregroundColor(.blue)
                        .padding(.leading, 20)

                        Spacer()

                        Button(action: {
                            viewModel.plantBomb()
                        }) {
                            Text("💣")
                                .font(.title)
                                .padding(20)
                                .background(Color.red)
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
        }
    }
}









#Preview {
    GameView()
}
