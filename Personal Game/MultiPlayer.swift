//
//  MultiPlayer.swift
//  Personal Game
//
//  Created by David Santiago Jamaica Galvis on 8/30/25.
//

import Foundation
import MultipeerConnectivity

class MultipeerManager: NSObject, ObservableObject {
    private let serviceType = "paint-battle"

    var onReceiveMove: ((Direction) -> Void)?
    var onReceiveAbility: ((String) -> Void)?
    var onReceiveSettings: ((NetSettings) -> Void)?

    let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    var session: MCSession!
    var advertiser: MCNearbyServiceAdvertiser?
    var browser: MCNearbyServiceBrowser?

    @Published var isConnected = false
    @Published var connectedPeer: MCPeerID?

    
    override init() {
        super.init()
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
    }

    // Hosting and Joining
    func startHosting() {
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    func joinGame() {
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }

    // Data
    private func send(_ message: [String: String]) {
        guard !session.connectedPeers.isEmpty else { return }
        do {
            let data = try JSONEncoder().encode(message)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print(" Error sending data: \(error.localizedDescription)")
        }
    }

    //  Send Move
    func sendMove(_ direction: Direction) {
        let message = ["type": "move", "dir": direction.rawValue]
        send(message)
    }

    //Send Ability
    func sendAbility(named ability: String) {
        let message = ["type": "ability", "ability": ability]
        send(message)
    }
    
    func sendSettings(_ settings: NetSettings) {
        do {
            let data = try JSONEncoder().encode([
                "type": "settings",
                "payload": String(data: try JSONEncoder().encode(settings), encoding: .utf8) ?? ""
            ])
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print(" Error sending settings: \(error.localizedDescription)")
        }
    }

}

extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.isConnected = state == .connected
            self.connectedPeer = state == .connected ? peerID : nil
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = try? JSONDecoder().decode([String: String].self, from: data) else { return }

        switch message["type"] {
        case "move":
            if let dirRaw = message["dir"], let direction = Direction(rawValue: dirRaw) {
                DispatchQueue.main.async {
                    self.onReceiveMove?(direction)
                }
            }

        case "ability":
            if let abilityName = message["ability"] {
                DispatchQueue.main.async {
                    self.onReceiveAbility?(abilityName)
                }
            }
        case "settings":
            if let jsonString = message["payload"],
               let jsonData = jsonString.data(using: .utf8),
               let settings = try? JSONDecoder().decode(NetSettings.self, from: jsonData) {
                DispatchQueue.main.async {
                    self.onReceiveSettings?(settings)
                }
            }


        default:
            break
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print(" Lost peer: \(peerID.displayName)")
    }
}


