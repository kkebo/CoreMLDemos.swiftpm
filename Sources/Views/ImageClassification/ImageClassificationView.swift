import ARKit
import SwiftUI

struct ImageClassificationView {
    @State private var state = ImageClassificationViewState()
    @State private var session = ARSession()
    private let configuration: AROrientationTrackingConfiguration = {
        let configuration = AROrientationTrackingConfiguration()
        return configuration
    }()

    private var imageResolution: CGSize { self.configuration.videoFormat.imageResolution }
    private var cameraFPS: Double { Double(self.configuration.videoFormat.framesPerSecond) }

    private func startSession() {
        self.session.run(self.configuration)
    }

    private func stopSession() {
        self.session.pause()
    }
}

extension ImageClassificationView: View {
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
        }
        .ignoresSafeArea()
        .overlay(alignment: .bottomTrailing) {
            FPSView(
                cameraFPS: self.cameraFPS,
                inferenceTime: .zero,
                renderingTime: .zero
            )
        }
    }
}

#Preview {
    ImageClassificationView()
}
