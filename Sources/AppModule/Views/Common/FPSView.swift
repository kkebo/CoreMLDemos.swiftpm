import SwiftUI

struct FPSView {
    let cameraFPS: Double
    let inferenceFPS: Double
    let renderingFPS: Double
}

extension FPSView: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("camera") + Text(":")
                Text(
                    self.cameraFPS,
                    format: .number.precision(.fractionLength(2))
                ) + Text("fps")
            }
            HStack {
                Text("inference") + Text(":")
                Text(
                    self.inferenceFPS,
                    format: .number.precision(.fractionLength(2))
                ) + Text("fps")
            }
            HStack {
                Text("rendering") + Text(":")
                Text(
                    self.renderingFPS,
                    format: .number.precision(.fractionLength(2))
                ) + Text("fps")
            }
        }
        .font(.body.monospacedDigit())
        .padding(10)
        .background(.thinMaterial)
    }
}

struct FPSView_Previews: PreviewProvider {
    static var previews: some View {
        FPSView(cameraFPS: 60, inferenceFPS: 60, renderingFPS: 60)
    }
}
