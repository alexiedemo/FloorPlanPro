import Foundation
import OSLog
import RoomPlan

enum PropertyType: String, CaseIterable, Identifiable, Codable {
    case apartment
    case house
    case townhouse
    case commercial
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .apartment: return "Apartment"
        case .house: return "House"
        case .townhouse: return "Townhouse"
        case .commercial: return "Commercial"
        case .other: return "Other"
        }
    }
}

struct Project: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    var propertyType: PropertyType
    var address: String
    var capturedRoomJSON: Data

    init(id: UUID = UUID(), createdAt: Date = Date(), propertyType: PropertyType, address: String, capturedRoomJSON: Data) {
        self.id = id
        self.createdAt = createdAt
        self.propertyType = propertyType
        self.address = address
        self.capturedRoomJSON = capturedRoomJSON
    }

    var capturedRoom: CapturedRoom? {
        try? JSONDecoder().decode(CapturedRoom.self, from: capturedRoomJSON)
    }
}

@MainActor
final class ProjectStore: ObservableObject {
    @Published private(set) var projects: [Project] = []

    @discardableResult
    func addProject(propertyType: PropertyType, address: String, capturedRoom: CapturedRoom) -> Project? {
        guard let data = try? JSONEncoder().encode(capturedRoom) else {
            AppLogger.error("Failed to encode CapturedRoom for project")
            return nil
        }

        let project = Project(propertyType: propertyType, address: address, capturedRoomJSON: data)
        projects.insert(project, at: 0)
        return project
    }

    func removeProjects(at offsets: IndexSet) {
        projects.remove(atOffsets: offsets)
    }
}

enum AppLogger {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.floorplanpro.app", category: "FloorPlanPro")

    static func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
