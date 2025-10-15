import CoreGraphics
import RoomPlan
import simd

struct PlanProjector {
    struct ProjectedWall: Identifiable, Hashable {
        let id: UUID = UUID()
        let start: CGPoint
        let end: CGPoint
        let lengthMeters: Double
    }

    struct ProjectionResult {
        let walls: [ProjectedWall]
        let boundingRect: CGRect
    }

    func project(room: CapturedRoom) -> ProjectionResult {
        var walls: [ProjectedWall] = []
        var minX = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude

        for wall in room.walls {
            let width = CGFloat(wall.dimensions.x)
            let transform = wall.transform
            let center = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            let rightAxis = SIMD3<Float>(transform.columns.0.x, transform.columns.0.y, transform.columns.0.z)
            let halfWidth = rightAxis * Float(width / 2)

            let start3D = center - halfWidth
            let end3D = center + halfWidth

            let start2D = CGPoint(x: CGFloat(start3D.x), y: CGFloat(-start3D.z))
            let end2D = CGPoint(x: CGFloat(end3D.x), y: CGFloat(-end3D.z))

            walls.append(ProjectedWall(start: start2D, end: end2D, lengthMeters: Double(width)))

            minX = min(minX, start2D.x, end2D.x)
            maxX = max(maxX, start2D.x, end2D.x)
            minY = min(minY, start2D.y, end2D.y)
            maxY = max(maxY, start2D.y, end2D.y)
        }

        let boundingRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        return ProjectionResult(walls: walls, boundingRect: boundingRect)
    }
}
