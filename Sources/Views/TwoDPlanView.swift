import RoomPlan
import SwiftUI

struct TwoDPlanView: View {
    private let projection: PlanProjector.ProjectionResult

    @State private var zoomFactor: CGFloat = 1
    @GestureState private var gestureZoom: CGFloat = 1
    @State private var panOffset: CGSize = .zero
    @GestureState private var gesturePan: CGSize = .zero

    init(capturedRoom: CapturedRoom) {
        self.projection = PlanProjector().project(room: capturedRoom)
    }

    var body: some View {
        GeometryReader { geometry in
            let totalScale = zoomFactor * gestureZoom
            let currentPan = CGSize(width: panOffset.width + gesturePan.width, height: panOffset.height + gesturePan.height)

            Canvas { context, size in
                guard !projection.walls.isEmpty else { return }

                let bounding = projection.boundingRect
                let baseScale = min(size.width / max(bounding.width, 0.1), size.height / max(bounding.height, 0.1)) * 0.8
                let scale = baseScale * totalScale

                context.translateBy(x: size.width / 2 + currentPan.width, y: size.height / 2 + currentPan.height)
                context.scaleBy(x: scale, y: scale)
                context.translateBy(x: -bounding.midX, y: -bounding.midY)

                var wallPath = Path()
                for wall in projection.walls {
                    wallPath.move(to: wall.start)
                    wallPath.addLine(to: wall.end)
                }

                context.stroke(wallPath, with: .color(.primary), lineWidth: 0.02)

                for wall in projection.walls {
                    drawLengthLabel(for: wall, using: &context)
                }
            }
            .background(Color(uiColor: .systemBackground))
            .gesture(zoomGesture.simultaneously(with: panGesture))
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Pinch to zoom", systemImage: "arrow.up.left.and.arrow.down.right")
                    Label("Drag to pan", systemImage: "hand.draw")
                    Text("TODO: Drag wall endpoints to edit with 0°/90° snapping.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
            }
        }
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureZoom) { value, state, _ in
                state = value
            }
            .onEnded { finalValue in
                zoomFactor = max(0.5, min(zoomFactor * finalValue, 5))
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .updating($gesturePan) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                panOffset.width += value.translation.width
                panOffset.height += value.translation.height
            }
    }

    private func drawLengthLabel(for wall: PlanProjector.ProjectedWall, using context: inout GraphicsContext) {
        let midpoint = CGPoint(x: (wall.start.x + wall.end.x) / 2, y: (wall.start.y + wall.end.y) / 2)
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        let length = formatter.string(from: NSNumber(value: wall.lengthMeters)) ?? "--"
        let text = Text("\(length) m")
        context.draw(text.font(.caption).foregroundColor(.blue), at: midpoint, anchor: .center)
    }
}
