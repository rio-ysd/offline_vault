import AVFoundation
import Combine
import Foundation

final class CameraViewModel: NSObject, ObservableObject {
    let session = AVCaptureSession()
    @Published private(set) var isRecording = false
    @Published var errorMessage: String?
    private let photoOutput = AVCapturePhotoOutput()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var photoContinuation: CheckedContinuation<Data, Error>?
    private var movieContinuation: CheckedContinuation<Data, Error>?

    func configure() {
        guard session.inputs.isEmpty else { return }
        session.beginConfiguration()
        session.sessionPreset = .high
        defer { session.commitConfiguration() }
        do {
            guard let camera = AVCaptureDevice.default(for: .video) else { throw CameraError.unavailable }
            let input = try AVCaptureDeviceInput(device: camera)
            guard session.canAddInput(input), session.canAddOutput(photoOutput), session.canAddOutput(movieOutput) else { throw CameraError.configurationFailed }
            session.addInput(input)
            session.addOutput(photoOutput)
            session.addOutput(movieOutput)
        } catch { errorMessage = error.localizedDescription }
    }

    func start() { DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() } }
    func stop() { DispatchQueue.global(qos: .userInitiated).async { self.session.stopRunning() } }

    func capturePhoto() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            photoContinuation = continuation
            photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        }
    }

    func startRecording() async throws -> Data {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("capture-\(UUID().uuidString).mov")
        isRecording = true
        return try await withCheckedThrowingContinuation { continuation in
            movieContinuation = continuation
            movieOutput.startRecording(to: url, recordingDelegate: self)
        }
    }

    func stopRecording() { movieOutput.stopRecording() }

    enum CameraError: LocalizedError {
        case unavailable, configurationFailed
        var errorDescription: String? { "カメラを準備できませんでした。" }
    }
}

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error { photoContinuation?.resume(throwing: error) }
        else if let data = photo.fileDataRepresentation() { photoContinuation?.resume(returning: data) }
        else { photoContinuation?.resume(throwing: CameraError.configurationFailed) }
        photoContinuation = nil
    }
}

extension CameraViewModel: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        isRecording = false
        if let error { movieContinuation?.resume(throwing: error) }
        else if let data = try? Data(contentsOf: outputFileURL) { movieContinuation?.resume(returning: data) }
        else { movieContinuation?.resume(throwing: CameraError.configurationFailed) }
        try? FileManager.default.removeItem(at: outputFileURL)
        movieContinuation = nil
    }
}
