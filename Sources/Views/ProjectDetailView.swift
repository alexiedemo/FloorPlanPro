import RoomPlan
import SwiftUI

struct ProjectDetailView: View {
    @EnvironmentObject private var store: ProjectStore
    let project: Project

    @State private var selection: Tab = .twoD
    @State private var shareURL: URL?
    @State private var showingShareSheet = false
    @State private var showingError = false
    @State private var errorMessage = ""

    private let exportService = ExportService()

    var body: some View {
        VStack(spacing: 0) {
            Picker("View mode", selection: $selection) {
                Text("2D").tag(Tab.twoD)
                Text("3D").tag(Tab.threeD)
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            exportBar
                .padding()
        }
        .navigationTitle(project.address)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
        .alert("Export failed", isPresented: $showingError, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text(errorMessage)
        })
    }

    @ViewBuilder
    private var content: some View {
        if let room = project.capturedRoom {
            switch selection {
            case .twoD:
                TwoDPlanView(capturedRoom: room)
            case .threeD:
                ThreeDQuickLookView(capturedRoom: room)
            }
        } else {
            ContentUnavailableView("Missing scan", systemImage: "exclamationmark.triangle", description: Text("The captured scan data could not be decoded."))
        }
    }

    private var exportBar: some View {
        HStack {
            Spacer()
            Button {
                export(.pdf)
            } label: {
                Label("Export PDF", systemImage: "doc.richtext")
            }
            Spacer()
            Button {
                export(.usdz)
            } label: {
                Label("Export USDZ", systemImage: "cube")
            }
            Spacer()
            Button {
                if shareURL != nil {
                    showingShareSheet = true
                }
            } label: {
                Label("Share last export", systemImage: "square.and.arrow.up")
            }
            .disabled(shareURL == nil)
            Spacer()
        }
    }

    private func export(_ type: ExportType) {
        guard let room = project.capturedRoom else {
            errorMessage = ExportService.ExportError.missingCapturedRoom.localizedDescription
            showingError = true
            return
        }

        do {
            let url: URL
            switch type {
            case .pdf:
                let projection = PlanProjector().project(room: room)
                url = try exportService.exportPDF(for: project, projection: projection)
            case .usdz:
                url = try exportService.exportUSDZ(from: project)
            }
            shareURL = url
            showingShareSheet = true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    enum ExportType {
        case pdf
        case usdz
    }

    enum Tab {
        case twoD
        case threeD
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
