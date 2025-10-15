import RoomPlan
import SwiftUI

struct RoomScanHostView: UIViewRepresentable {
    typealias UIViewType = RoomCaptureView

    @Binding var isScanning: Bool
    var onCompleted: (CapturedRoom) -> Void
    var onError: (Error) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(isScanning: $isScanning, onCompleted: onCompleted, onError: onError)
    }

    func makeUIView(context: Context) -> RoomCaptureView {
        let captureView = RoomCaptureView(frame: .zero)
        context.coordinator.attach(to: captureView)
        return captureView
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
        if !isScanning {
            context.coordinator.stopSession()
        }
    }

    final class Coordinator: NSObject, RoomCaptureSessionDelegate {
        @Binding private var isScanning: Bool
        private let onCompleted: (CapturedRoom) -> Void
        private let onError: (Error) -> Void

        private weak var captureView: RoomCaptureView?
        private let builder = RoomBuilder(options: [.beautifyObjects])
    private var hasDeliveredResult = false
    private var hasStarted = false

        init(isScanning: Binding<Bool>, onCompleted: @escaping (CapturedRoom) -> Void, onError: @escaping (Error) -> Void) {
            self._isScanning = isScanning
            self.onCompleted = onCompleted
            self.onError = onError
            super.init()
        }

        func attach(to captureView: RoomCaptureView) {
            self.captureView = captureView
            captureView.captureSession.delegate = self
            startSession()
        }

        func startSession() {
            guard RoomCaptureSession.isSupported else {
                onError(RoomScanError.unsupportedDevice)
                return
            }

            guard let session = captureView?.captureSession else {
                onError(RoomScanError.internalFailure)
                return
            }

            var configuration = RoomCaptureSession.Configuration()
            configuration.isCoachingEnabled = true

            session.run(configuration: configuration)
            hasStarted = true
            isScanning = true
        }

        func stopSession() {
            captureView?.captureSession.stop()
            isScanning = false
        }

        // MARK: - RoomCaptureSessionDelegate

        func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
            guard !hasDeliveredResult else { return }
            hasDeliveredResult = true
            isScanning = false

            if let error {
                onError(error)
                return
            }

            Task { @MainActor in
                do {
                    let room = try await builder.capturedRoom(from: data)
                    onCompleted(room)
                } catch {
                    onError(error)
                }
            }
        }

        enum RoomScanError: LocalizedError {
            case unsupportedDevice
            case internalFailure

            var errorDescription: String? {
                switch self {
                case .unsupportedDevice:
                    return "Room scanning requires a LiDAR-capable device."
                case .internalFailure:
                    return "The scanning session could not be configured."
                }
            }
        }
    }
}
