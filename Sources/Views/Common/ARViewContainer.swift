import ARKit
import RealityKit
import SwiftUI

struct ARViewContainer: UIViewRepresentable {
    typealias UIViewType = ARView

    let session: ARSession

    func makeUIView(context: Context) -> UIViewType {
        let view = UIViewType(
            frame: .zero,
            cameraMode: .ar,
            automaticallyConfigureSession: false
        )
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.session = self.session
    }
}

struct ARViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        ARViewContainer(session: ARSession())
    }
}
