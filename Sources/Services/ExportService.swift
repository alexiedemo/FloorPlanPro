import Foundation
import PDFKit
import RoomPlan
import UIKit

struct ExportService {
    enum ExportError: LocalizedError {
        case missingCapturedRoom

        var errorDescription: String? {
            switch self {
            case .missingCapturedRoom:
                return "The captured room data could not be read."
            }
        }
    }

    func exportUSDZ(from project: Project) throws -> URL {
        guard let capturedRoom = project.capturedRoom else {
            throw ExportError.missingCapturedRoom
        }

        let tempDirectory = FileManager.default.temporaryDirectory
        let usdzURL = tempDirectory.appendingPathComponent("FloorPlanPro-\(project.id).usdz")
        let metadataURL = tempDirectory.appendingPathComponent("FloorPlanPro-\(project.id).json")

        try? FileManager.default.removeItem(at: usdzURL)
        try? FileManager.default.removeItem(at: metadataURL)

        try capturedRoom.export(to: usdzURL, metadataURL: metadataURL, modelProvider: nil, exportOptions: [.parametric])
        return usdzURL
    }

    func exportPDF(for project: Project, projection: PlanProjector.ProjectionResult) throws -> URL {
        let pageWidth: CGFloat = 842 // A4 landscape points
        let pageHeight: CGFloat = 595
        let margin: CGFloat = 36
        let contentRect = CGRect(x: margin, y: margin, width: pageWidth - margin * 2, height: pageHeight - margin * 2)

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("FloorPlanPro-\(project.id).pdf")

        try? FileManager.default.removeItem(at: url)

        try renderer.writePDF(to: url) { context in
            context.beginPage()
            drawHeader(for: project, contentRect: contentRect)
            drawPlan(projection: projection, in: contentRect)
            drawFooter(in: contentRect)
        }

        return url
    }

    private func drawHeader(for project: Project, contentRect: CGRect) {
        let title = "FloorPlanPro — \(project.propertyType.displayName)"
        let subtitle = project.address
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let timestamp = formatter.string(from: project.createdAt)

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .title2)
        ]

        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .headline)
        ]

        let timestampAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .subheadline),
            .foregroundColor: UIColor.secondaryLabel
        ]

        let headerOrigin = CGPoint(x: contentRect.minX, y: contentRect.minY)
        title.draw(at: headerOrigin, withAttributes: titleAttributes)
        subtitle.draw(at: CGPoint(x: headerOrigin.x, y: headerOrigin.y + 28), withAttributes: subtitleAttributes)
        timestamp.draw(at: CGPoint(x: headerOrigin.x, y: headerOrigin.y + 52), withAttributes: timestampAttributes)
    }

    private func drawPlan(projection: PlanProjector.ProjectionResult, in contentRect: CGRect) {
        guard !projection.walls.isEmpty else { return }

        let bounding = projection.boundingRect.insetBy(dx: -0.5, dy: -0.5)
        let scaleX = contentRect.width / bounding.width
        let scaleY = contentRect.height / bounding.height
        let scale = min(scaleX, scaleY)

        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()

        // Translate origin to bottom-left to account for flipped coordinates.
        context?.translateBy(x: contentRect.midX, y: contentRect.midY)
        context?.scaleBy(x: scale, y: scale)
        context?.translateBy(x: -bounding.midX, y: -bounding.midY)

        let wallPath = UIBezierPath()
        UIColor.label.setStroke()
        wallPath.lineWidth = 0.02 // metres; scaled visually

        for wall in projection.walls {
            wallPath.move(to: wall.start)
            wallPath.addLine(to: wall.end)
        }

        wallPath.stroke()

        // Draw lengths
        for wall in projection.walls {
            drawLengthLabel(for: wall, in: context, bounding: bounding)
        }

        context?.restoreGState()
    }

    private func drawLengthLabel(for wall: PlanProjector.ProjectedWall, in context: CGContext?, bounding: CGRect) {
        let midpoint = CGPoint(x: (wall.start.x + wall.end.x) / 2, y: (wall.start.y + wall.end.y) / 2)
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.numberStyle = .decimal
        let lengthString = formatter.string(from: NSNumber(value: wall.lengthMeters)) ?? "--"
        let label = "\(lengthString) m"
        // TODO: Support feet/inches toggle alongside metric output.

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: UIColor.systemBlue
        ]

        let textSize = label.size(withAttributes: attributes)
        let labelRect = CGRect(x: midpoint.x - textSize.width / 2, y: midpoint.y - textSize.height / 2, width: textSize.width, height: textSize.height)

        context?.saveGState()
        context?.translateBy(x: labelRect.origin.x, y: labelRect.origin.y)
        label.draw(at: .zero, withAttributes: attributes)
        context?.restoreGState()
    }

    private func drawFooter(in contentRect: CGRect) {
        let disclaimer = "Not to scale; approximate only; buyers to make independent enquiries."
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.secondaryLabel
        ]

        let textSize = disclaimer.size(withAttributes: attributes)
        let origin = CGPoint(x: contentRect.midX - textSize.width / 2, y: contentRect.maxY - textSize.height)
        disclaimer.draw(at: origin, withAttributes: attributes)
    }
}
