import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var library: MediaLibrary
    @StateObject private var camera = CameraViewModel()
    @StateObject private var transfer = PeerTransferService()
    @State private var tab = 0
    @State private var alertMessage: String?

    var body: some View {
        TabView(selection: $tab) {
            CaptureScreen(camera: camera) { data, kind in
                do { try library.add(data: data, kind: kind) }
                catch { alertMessage = "保存に失敗しました: \(error.localizedDescription)" }
            }
            .tabItem { Label("撮影", systemImage: "camera.fill") }.tag(0)
            LibraryScreen(items: library.items, transfer: transfer, library: library, alertMessage: $alertMessage)
                .tabItem { Label("保管庫", systemImage: "square.grid.2x2.fill") }.tag(1)
        }
        .tint(.yellow)
        .onChange(of: transfer.receivedURL) { _, url in
            guard let url, let data = try? Data(contentsOf: url) else { return }
            let kind: MediaItem.Kind = url.pathExtension.lowercased() == "mov" ? .video : .photo
            do { try library.add(data: data, kind: kind) }
            catch { alertMessage = "受信ファイルを保存できませんでした: \(error.localizedDescription)" }
            transfer.receivedURL = nil
        }
        .alert("OfflineVault", isPresented: .constant(alertMessage != nil), presenting: alertMessage) { _ in Button("閉じる") { alertMessage = nil } } message: { Text($0) }
    }
}

struct CaptureScreen: View {
    @ObservedObject var camera: CameraViewModel
    let onCaptured: (Data, MediaItem.Kind) -> Void
    @State private var isBusy = false

    var body: some View {
        ZStack(alignment: .bottom) {
            CameraPreview(session: camera.session).ignoresSafeArea()
            LinearGradient(colors: [.clear, .black.opacity(0.9)], startPoint: .center, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 18) {
                Text("端末内だけに保存")
                    .font(.headline)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(.black.opacity(0.55), in: Capsule())
                HStack(spacing: 28) {
                    Button { Task { await capturePhoto() } } label: { Image(systemName: "camera.circle.fill").font(.system(size: 72)).symbolRenderingMode(.palette).foregroundStyle(.white, .yellow) }
                    Button { Task { await toggleVideo() } } label: { Image(systemName: camera.isRecording ? "stop.circle.fill" : "record.circle").font(.system(size: 58)).foregroundStyle(camera.isRecording ? .red : .white) }
                }
                Text(camera.isRecording ? "録画中" : "写真またはビデオ")
                    .font(.caption).foregroundStyle(.white.opacity(0.8))
            }.padding(.bottom, 24)
        }
        .task { camera.configure(); camera.start() }
        .onDisappear { camera.stop() }
        .overlay { if isBusy { ProgressView().tint(.white).scaleEffect(1.5) } }
    }

    private func capturePhoto() async { isBusy = true; defer { isBusy = false }; if let data = try? await camera.capturePhoto() { onCaptured(data, .photo) } }
    private func toggleVideo() async {
        if camera.isRecording { camera.stopRecording() }
        else if let data = try? await camera.startRecording() { onCaptured(data, .video) }
    }
}

struct LibraryScreen: View {
    let items: [MediaItem]
    @ObservedObject var transfer: PeerTransferService
    @ObservedObject var library: MediaLibrary
    @Binding var alertMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView { LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack { Rectangle().fill(.white.opacity(0.08)); Image(systemName: item.kind.symbolName).font(.system(size: 38)).foregroundStyle(.yellow) }.aspectRatio(1, contentMode: .fit)
                        Text(item.createdAt, format: .dateTime.month().day().hour().minute()).font(.caption).foregroundStyle(.secondary)
                        HStack { Button { do { try transfer.send(library.url(for: item)) } catch { alertMessage = error.localizedDescription } } label: { Label("送る", systemImage: "arrow.up.circle") }.buttonStyle(.bordered).controlSize(.small); Spacer(); Button(role: .destructive) { library.delete(item) } label: { Image(systemName: "trash") }.buttonStyle(.borderless) }
                    }.padding(10).background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                }
            }.padding() }
            .navigationTitle("保管庫")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { VStack(alignment: .trailing) { Image(systemName: "antenna.radiowaves.left.and.right"); Text(transfer.status).font(.caption2) } } }
        }
    }
}
