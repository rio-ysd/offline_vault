import Foundation
import MultipeerConnectivity
import UIKit

final class PeerTransferService: NSObject, ObservableObject {
    @Published private(set) var peers: [MCPeerID] = []
    @Published private(set) var status = "近くの端末を検索中"
    @Published var receivedURL: URL?
    private let serviceType = "offline-vault"
    private let peer = MCPeerID(displayName: UIDevice.current.name)
    private lazy var session: MCSession = {
        let session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()
    private lazy var advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: serviceType)
    private lazy var browser = MCNearbyServiceBrowser(peer: peer, serviceType: serviceType)

    override init() {
        super.init()
        advertiser.delegate = self
        browser.delegate = self
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    deinit { advertiser.stopAdvertisingPeer(); browser.stopBrowsingForPeers() }

    func send(_ url: URL) throws {
        guard !session.connectedPeers.isEmpty else { throw TransferError.noPeer }
        status = "送信中"
        for peer in session.connectedPeers {
            session.sendResource(at: url, withName: url.lastPathComponent, toPeer: peer) { [weak self] error in
                DispatchQueue.main.async { self?.status = error == nil ? "送信完了" : "送信に失敗しました" }
            }
        }
    }

    enum TransferError: LocalizedError { case noPeer; var errorDescription: String? { "接続中の端末がありません。" } }
}

extension PeerTransferService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) { DispatchQueue.main.async { self.status = state == .connected ? "接続済み: \(peerID.displayName)" : "近くの端末を検索中" } }
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        guard error == nil, let localURL else { return }
        DispatchQueue.main.async {
            self.receivedURL = localURL
            self.status = "受信完了"
        }
    }
}

extension PeerTransferService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) { invitationHandler(true, session) }
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) { status = "共有を開始できませんでした" }
}

extension PeerTransferService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) { browser.invitePeer(peerID, to: session, withContext: nil, timeout: 15) }
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) { status = "近くの端末を検索できませんでした" }
}
