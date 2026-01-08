import ARKit
import CoreML
import Observation
import VideoToolbox

@Observable
final class ImageClassificationViewState: NSObject {
    @ObservationIgnored private var rotationSession: VTPixelRotationSession?
    @ObservationIgnored private var bufferPool: CVPixelBufferPool?

    // ML model
    var model: MLModel? = nil
    let modelConfiguration: MLModelConfiguration = {
        let config = MLModelConfiguration()
        config.computeUnits = .all
        return config
    }()
    let inputName = "image"

    @inline(__always)
    var isLoading: Bool { self.model == nil }

    override init() {
        VTPixelRotationSessionCreate(kCFAllocatorDefault, &self.rotationSession)
    }

    func loadModel() async throws {
        guard
            let url = Bundle.main.url(
                forResource: "FastViTMA36F16",
                withExtension: "mlpackage"
            )
        else { preconditionFailure() }
        let compiledModelURL = try await MLModel.compileModel(at: url)
        let model = try await MLModel.load(
            contentsOf: compiledModelURL,
            configuration: self.modelConfiguration
        )
        guard
            let imageConstraint = model.modelDescription
                .inputDescriptionsByName[self.inputName]?
                .imageConstraint
        else { preconditionFailure() }
        self.model = model
        let poolAttrs = [kCVPixelBufferPoolMinimumBufferCountKey: 10] as CFDictionary
        let bufferAttrs =
        [
            kCVPixelBufferWidthKey as String: imageConstraint.pixelsWide,
            kCVPixelBufferHeightKey as String: imageConstraint.pixelsHigh,
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:],
            kCVPixelBufferBytesPerRowAlignmentKey as String: 64,
        ] as CFDictionary
        CVPixelBufferPoolCreate(kCFAllocatorDefault, poolAttrs, bufferAttrs, &self.bufferPool)
    }

    private func inference(
        model: MLModel,
        imageBuffer: CVPixelBuffer,
        orientation: UIInterfaceOrientation?,
        rotationSession: VTPixelRotationSession,
        bufferPool: CVPixelBufferPool
    ) throws -> (result: MLFeatureProvider, duration: Duration) {
        // create a new buffer
        var rotatedBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, bufferPool, &rotatedBuffer)
        guard let rotatedBuffer else { preconditionFailure() }

        let angle =
        switch orientation {
        case .portrait: kVTRotation_CW90
        case .portraitUpsideDown: kVTRotation_CCW90
        case .landscapeLeft: kVTRotation_180
        case .landscapeRight, _: kVTRotation_0
        }
        VTSessionSetProperty(rotationSession, key: kVTPixelRotationPropertyKey_Rotation, value: angle)

        // rotate and scale
        let status = VTPixelRotationSessionRotateImage(rotationSession, imageBuffer, rotatedBuffer)
        guard status == noErr else { preconditionFailure() }
        
        let input = try MLDictionaryFeatureProvider(
            dictionary: [
                self.inputName: MLFeatureValue(pixelBuffer: rotatedBuffer)
            ]
        )

        let start = ContinuousClock.now
        let result = try model.prediction(from: input)
        let duration = start.duration(to: .now)

        return (result, duration) 
    }
}

extension ImageClassificationViewState: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let model, let rotationSession, let bufferPool else { return }
        let orientation = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.interfaceOrientation
        guard
            let (result, duration) = try? self.inference(
                model: model,
                imageBuffer: frame.capturedImage,
                orientation: orientation,
                rotationSession: rotationSession,
                bufferPool: bufferPool
            )
        else { preconditionFailure() }
    }
}
