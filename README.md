# FloorPlanPro

FloorPlanPro is a SwiftUI iOS 17+ application that leverages Apple's RoomPlan APIs to capture LiDAR scans of interior spaces and produce editable 2D and 3D floor plans. Professionals can preview scans, annotate measurements, and export deliverables ready for client review.

## Device and platform requirements

- iOS 17 or later
- LiDAR-capable iPhone or iPad Pro (2020 models or newer)
- Xcode 15 or later on macOS for development and deployment

## Quickstart

1. Clone the repository:
   ```sh
   git clone https://github.com/<your-org>/FloorPlanPro.git
   cd FloorPlanPro
   ```
2. Open `FloorPlanPro.xcodeproj` in Xcode 15.
3. In the project target Info tab, ensure `NSCameraUsageDescription` includes:
   > Camera access is required to scan rooms with RoomPlan.
   (You can copy the key from `Resources/InfoPlistSnippet.plist`).
4. Select a physical LiDAR-capable device and run the app.

## Features

- Guided RoomPlan capture flow with contextual tips.
- Automatic persistence of captured rooms and project metadata.
- Interactive 2D plan preview with pinch-to-zoom and pan gestures (editing TODOs left in-line).
- QuickLook-powered 3D USDZ preview.
- One-tap export to USDZ or vector-style PDF including wall lengths and disclaimers.
- Share sheet integration to distribute the latest export.

## Known limitations & roadmap

- Single-room MVP — multi-room stitching is a planned enhancement.
- TODO markers for draggable wall endpoints and 0° / 90° snapping remain.
- Imperial unit labels (feet & inches) TODO alongside metric output.
- AI-assisted room labelling and DXF/SVG export integrations are under evaluation.
- Cloud sync (iCloud Drive / CloudKit) is currently out of scope.

## Architecture highlights

- Pure SwiftUI scene hierarchy with navigation-driven capture and detail flows.
- ObservableObject-based in-memory persistence for MVP; swap in your storage of choice.
- Dedicated services for RoomPlan hosting, geometric projection, and export workflows.
- Lightweight PDF generation pipeline via `UIGraphicsPDFRenderer` with compliance disclaimer.

## Development scripts

- `scripts/pre-commit` — optional SwiftFormat / SwiftLint runner (non-fatal if unavailable).
- `scripts/hooks/commit-msg` — Conventional Commits guard (install manually, see below).

To enable the commit message hook locally:
```sh
mkdir -p .git/hooks
cp scripts/hooks/commit-msg .git/hooks/commit-msg
chmod +x .git/hooks/commit-msg
```

## Continuous integration

GitHub Actions workflows validate builds (`.github/workflows/ci.yml`) and prepare unsigned release archives (`.github/workflows/release.yml`). Both disable code signing to support CI environments.

## Legal notice

Exported plans include the footer:
> Not to scale; approximate only; buyers to make independent enquiries.

FloorPlanPro is provided “as is” with no warranty. Always verify measurements independently before relying on them for contractual, compliance, or safety decisions.