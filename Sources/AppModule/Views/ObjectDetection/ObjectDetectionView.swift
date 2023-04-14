import SwiftUI

struct ObjectDetectionView {
    @StateObject private var state = ObjectDetectionViewState()
}

extension ObjectDetectionView: View {
    var body: some View {
        ZStack {
            if self.state.model == nil {
                HStack(spacing: 5) {
                    ProgressView()
                    Text("Loading a model...")
                }
            } else {
                self.realtimePreview
            }
        }
        .task {
            try? await self.state.loadModel()
        }
        .onAppear {
            self.state.startSession()
        }
        .onDisappear {
            self.state.stopSession()
        }
    }

    private var realtimePreview: some View {
        ZStack {
            ARViewContainer(session: self.state.session)
            OverlayView(
                frameData: self.state.frameData,
                imageResolution: self.state.configuration.videoFormat.imageResolution
            )
        }
        .ignoresSafeArea()
        .overlay(alignment: .bottomTrailing) {
            FPSView(
                cameraFPS: Double(self.state.configuration.videoFormat.framesPerSecond),
                inferenceTime: self.state.frameData?.inferenceTime ?? .zero,
                renderingTime: self.state.renderingTime ?? .zero
            )
        }
    }
}

struct ObjectDetectionView_Previews: PreviewProvider {
    static var previews: some View {
        ObjectDetectionView()
    }
}
