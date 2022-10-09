import SwiftUI
import Vision

struct OverlayView {
    let frameData: FrameData?
    let imageResolution: CGSize
}

extension OverlayView: View {
    var body: some View {
        Canvas { context, size in
            guard let frameData = self.frameData else { return }
            let imageWidth = self.imageResolution.width
            let imageHeight = self.imageResolution.height
            let scale = max(size.width / imageWidth, size.height / imageHeight)
            let scaledWidth = imageWidth * scale
            let scaledHeight = imageHeight * scale
            let cropLeft = scaledWidth > size.width ? (scaledWidth - size.width) / 2 : 0
            let cropTop = scaledHeight > size.height ? (scaledHeight - size.height) / 2 : 0
            for det in frameData.detections {
                let bbox = VNImageRectForNormalizedRect(
                    det.bbox,
                    Int(scaledWidth),
                    Int(scaledHeight)
                )
                    .applying(.init(scaleX: 1, y: -1).translatedBy(x: 0, y: -scaledHeight))
                    .offsetBy(dx: -cropLeft, dy: -cropTop)
                context.stroke(Path(bbox), with: .color(.red), lineWidth: 1)
                context.draw(
                    Text("\(cocoClasses[det.id]): \(det.confidence)")
                        .foregroundColor(.red),
                    in: bbox
                )
            }
        }
    }
}

struct OverlayView_Previews: PreviewProvider {
    static var previews: some View {
        OverlayView(frameData: nil, imageResolution: .zero)
    }
}
