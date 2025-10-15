import RoomPlan
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: ProjectStore
    @State private var showingNewScan = false
    @State private var selectedProject: Project?

    var body: some View {
        NavigationStack {
            Group {
                if store.projects.isEmpty {
                    emptyState
                } else {
                    projectList
                }
            }
            .navigationTitle("FloorPlanPro")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewScan = true }) {
                        Label("New Scan", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $selectedProject) { project in
                ProjectDetailView(project: project)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingNewScan) {
                NavigationStack {
                    NewScanFlowView { project in
                        showingNewScan = false
                        selectedProject = project
                    }
                    .environmentObject(store)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Scan your first space")
                .font(.title2.bold())
            Text("Capture accurate floor plans using LiDAR-enabled RoomPlan scanning.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Start scanning") {
                showingNewScan = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var projectList: some View {
        List {
            Section(header: Text("Recent projects")) {
                ForEach(store.projects) { project in
                    Button(action: { selectedProject = project }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(project.address)
                                    .font(.headline)
                                Text(project.propertyType.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(project.createdAt, style: .date)
                                .font(.footnote)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .onDelete(perform: store.removeProjects)
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let store = ProjectStore()
        return DashboardView()
            .environmentObject(store)
    }
}
