import RoomPlan
import SwiftUI

struct ScanView: View {
    @EnvironmentObject private var store: ProjectStore
    @Environment(\.dismiss) private var dismiss

    let propertyType: PropertyType
    let address: String
    var onCompleted: (Project) -> Void

    @State private var isScanning = true
    @State private var showingError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        ZStack(alignment: .top) {
            RoomScanHostView(isScanning: $isScanning, onCompleted: handleRoomCaptured, onError: handleError)
                .edgesIgnoringSafeArea(.all)

            VStack {
                instructions
                Spacer()
                controlBar
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .alert("Scan error", isPresented: $showingError, actions: {
            Button("OK", role: .cancel) {
                dismiss()
            }
        }, message: {
            Text(errorMessage)
        })
    }

    private var instructions: some View {
        VStack(spacing: 8) {
            Text("Move slowly to map the room")
                .font(.headline)
                .padding(.top, 16)
            Text("Ensure good lighting and keep the LiDAR sensor unobstructed.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var controlBar: some View {
        HStack {
            Button(role: .cancel) {
                isScanning = false
                dismiss()
            } label: {
                Label("Cancel", systemImage: "xmark")
            }
            .buttonStyle(.bordered)

            Spacer()

            if isScanning {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            } else {
                Text("Processing scan…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func handleRoomCaptured(_ room: CapturedRoom) {
        guard let project = store.addProject(propertyType: propertyType, address: address, capturedRoom: room) else {
            handleError(RoomScanError.encodingFailure)
            return
        }

        isScanning = false
        onCompleted(project)
        dismiss()
    }

    private func handleError(_ error: Error) {
        AppLogger.error("Scan failed: \(error.localizedDescription)")
        errorMessage = error.localizedDescription
        showingError = true
    }

    enum RoomScanError: LocalizedError {
        case encodingFailure

        var errorDescription: String? {
            switch self {
            case .encodingFailure:
                return "The captured scan data could not be saved."
            }
        }
    }
}
