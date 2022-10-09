import SwiftUI

struct ObjectDetectionView {
    @StateObject private var state = ObjectDetectionViewState()
}

extension ObjectDetectionView: View {
    var body: some View {
        ZStack {
            ZStack {
                ARViewContainer(session: self.state.session)
                OverlayView(
                    frameData: self.state.frameData,
                    imageResolution: self.state.configuration.videoFormat.imageResolution
                )
            }
            .ignoresSafeArea()
            FPSView(
                cameraFPS: Double(self.state.configuration.videoFormat.framesPerSecond),
                inferenceFPS: self.state.frameData?.fps ?? 0,
                renderingFPS: 0
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .onAppear {
            self.state.startSession()
        }
        .onDisappear {
            self.state.stopSession()
        }
    }
}

struct ObjectDetectionView_Previews: PreviewProvider {
    static var previews: some View {
        ObjectDetectionView()
    }
}
