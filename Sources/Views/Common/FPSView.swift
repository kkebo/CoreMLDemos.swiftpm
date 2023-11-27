import SwiftUI

struct FPSView {
    let cameraFPS: Double
    let inferenceTime: Duration
    let renderingTime: Duration
}

extension FPSView: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("camera") + Text(":")
                Text(
                    self.cameraFPS,
                    format: .number.precision(.fractionLength(2))
                ) + Text(" ") + Text("fps")
            }
            HStack {
                Text("inference") + Text(":")
                Text(self.inferenceTime, format: .units(allowed: [.milliseconds]))
            }
            HStack {
                Text("rendering") + Text(":")
                Text(self.renderingTime, format: .units(allowed: [.milliseconds]))
            }
        }
        .font(.body.monospacedDigit())
        .padding(10)
        .background(.thinMaterial)
    }
}

struct FPSView_Previews: PreviewProvider {
    static var previews: some View {
        FPSView(cameraFPS: 60, inferenceTime: .zero, renderingTime: .zero)
    }
}
