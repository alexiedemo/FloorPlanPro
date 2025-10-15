import SwiftUI

struct NewScanFlowView: View {
    @EnvironmentObject private var store: ProjectStore
    @State private var propertyType: PropertyType = .house
    @State private var address: String = ""
    @State private var beginScan = false

    var onCompleted: (Project) -> Void

    var body: some View {
        Form {
            Section(header: Text("Property details")) {
                Picker("Property type", selection: $propertyType) {
                    ForEach(PropertyType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)

                TextField("Street address", text: $address)
                    .textContentType(.fullStreetAddress)
                    .autocorrectionDisabled()
            }

            Section {
                Button(action: { beginScan = true }) {
                    Label("Start RoomPlan scan", systemImage: "camera.viewfinder")
                }
                .disabled(address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("New scan")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $beginScan) {
            ScanView(propertyType: propertyType, address: address) { project in
                onCompleted(project)
            }
            .environmentObject(store)
        }
    }
}
