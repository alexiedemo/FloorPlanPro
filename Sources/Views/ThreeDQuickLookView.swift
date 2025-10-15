import QuickLook
import RoomPlan
import SwiftUI

struct ThreeDQuickLookView: UIViewControllerRepresentable {
    let capturedRoom: CapturedRoom

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        context.coordinator.preparePreview(for: capturedRoom)
        return controller
    }

    func updateUIViewController(_ controller: QLPreviewController, context: Context) {
        context.coordinator.preparePreview(for: capturedRoom)
        controller.reloadData()
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        private var previewItem: PreviewItem?

        func preparePreview(for room: CapturedRoom) {
            let tempDirectory = FileManager.default.temporaryDirectory
            let url = tempDirectory.appendingPathComponent("LivePreview.usdz")
            let metadata = tempDirectory.appendingPathComponent("LivePreview.json")
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: metadata)

            do {
                try room.export(to: url, metadataURL: metadata, modelProvider: nil, exportOptions: [.parametric])
                previewItem = PreviewItem(url: url)
            } catch {
                AppLogger.error("Unable to prepare Quick Look preview: \(error.localizedDescription)")
            }
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            previewItem == nil ? 0 : 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            previewItem ?? PreviewItem(url: URL(fileURLWithPath: "/dev/null"))
        }

        final class PreviewItem: NSObject, QLPreviewItem {
            private let url: URL

            init(url: URL) {
                self.url = url
                super.init()
            }

            var previewItemURL: URL? { url }
        }
    }
}
