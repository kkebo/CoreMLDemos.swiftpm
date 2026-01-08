import SwiftUI

struct OverlayView {
    let frameData: FrameData?
    let imageResolution: CGSize
}

extension OverlayView: View {
    var body: some View {
        Canvas { context, size in
            guard let frameData = self.frameData else { return }
            let (imageWidth, imageHeight) =
                switch frameData.orientation {
                case .portrait, .portraitUpsideDown:
                    (self.imageResolution.height, self.imageResolution.width)
                case .landscapeLeft, .landscapeRight, _:
                    (self.imageResolution.width, self.imageResolution.height)
                }
            let scale = max(size.width / imageWidth, size.height / imageHeight)
            let scaledWidth = imageWidth * scale
            let scaledHeight = imageHeight * scale
            let cropLeft = scaledWidth > size.width ? (scaledWidth - size.width) / 2 : 0
            let cropTop = scaledHeight > size.height ? (scaledHeight - size.height) / 2 : 0
            for det in frameData.detections {
                let bbox = det.bbox.applying(
                    .init(translationX: -cropLeft, y: -cropTop)
                        .scaledBy(x: scaledWidth, y: scaledHeight)
                )
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
