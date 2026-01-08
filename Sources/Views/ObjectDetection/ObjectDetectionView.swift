import ARKit
import SwiftUI

struct ObjectDetectionView {
    @State private var state = ObjectDetectionViewState()
    @State private var session = ARSession()
    private let configuration: AROrientationTrackingConfiguration = {
        let configuration = AROrientationTrackingConfiguration()
        return configuration
    }()

    @inline(__always)
    private var imageResolution: CGSize { self.configuration.videoFormat.imageResolution }
    @inline(__always)
    private var cameraFPS: Double { Double(self.configuration.videoFormat.framesPerSecond) }

    private func startSession() {
        self.session.run(self.configuration)
    }

    private func stopSession() {
        self.session.pause()
    }
}

extension ObjectDetectionView: View {
    var body: some View {
        ZStack {
            if self.state.isLoading {
                HStack(spacing: 5) {
                    ProgressView()
                    Text("Loading a model...")
                }
            } else {
                self.realtimePreview
            }
        }
        .task {
            self.session.delegate = self.state
            try? await self.state.loadModel()
        }
        .onAppear {
            self.startSession()
        }
        .onDisappear {
            self.stopSession()
        }
    }

    private var realtimePreview: some View {
        ZStack {
            ARViewContainer(session: self.session)
            OverlayView(frameData: self.state.frameData, imageResolution: self.imageResolution)
        }
        .ignoresSafeArea()
        .overlay(alignment: .bottomTrailing) {
            FPSView(
                cameraFPS: self.cameraFPS,
                inferenceTime: self.state.frameData?.inferenceTime ?? .zero,
                renderingTime: self.state.renderingTime ?? .zero
            )
        }
    }
}

#Preview {
    ObjectDetectionView()
}
