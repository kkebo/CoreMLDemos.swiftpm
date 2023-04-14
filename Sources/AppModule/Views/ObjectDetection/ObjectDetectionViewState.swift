import ARKit
import Combine
import CoreML
import VideoToolbox
import Vision

struct Detection {
    var id: Int
    var confidence: Double
    var bbox: CGRect
}

struct FrameData {
    var detections: [Detection]
    var inferenceTime: Duration
}

@MainActor
final class ObjectDetectionViewState: NSObject {
    @Published var frameData: FrameData?
    @Published var renderingTime: Duration?

    // camera
    let session = ARSession()
    let configuration: AROrientationTrackingConfiguration = {
        let configuration = AROrientationTrackingConfiguration()
        return configuration
    }()

    // ML model
    let model: MLModel
    let modelConfiguration: MLModelConfiguration = {
        let config = MLModelConfiguration()
        config.computeUnits = .all
        return config
    }()
    let inputName = "image"
    let iouThresholdName = "iouThreshold"
    let confidenceThresholdName = "confidenceThreshold"
    let outputName = "coordinates"
    let iouThreshold = 0.5
    let confidenceThreshold = 0.3
    let imageConstraint: MLImageConstraint
    let imageOptions: [MLFeatureValue.ImageOption: Any] = [
        .cropAndScale: VNImageCropAndScaleOption.scaleFill
    ]

    override init() {
        guard
            let url = Bundle.main.url(
                forResource: "YOLOv3TinyInt8LUT",
                withExtension: "mlmodel"
            ),
            let model = try? MLModel(
                contentsOf: MLModel.compileModel(at: url),
                configuration: self.modelConfiguration
            ),
            let imageConstraint = model.modelDescription
                .inputDescriptionsByName[self.inputName]?
                .imageConstraint
        else { preconditionFailure() }
        self.model = model
        self.imageConstraint = imageConstraint

        super.init()

        self.session.delegate = self
    }

    func startSession() {
        self.session.run(self.configuration)
    }

    func stopSession() {
        self.session.pause()
    }

    private func inference(
        imageBuffer: CVPixelBuffer
    ) throws -> (result: MLFeatureProvider, duration: Duration) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(imageBuffer, options: nil, imageOut: &cgImage)
        guard let cgImage else { preconditionFailure() }

        let featureValue = try MLFeatureValue(
            cgImage: cgImage,
            constraint: self.imageConstraint,
            options: self.imageOptions
        )
        let input = try MLDictionaryFeatureProvider(
            dictionary: [
                self.inputName: featureValue,
                self.iouThresholdName: self.iouThreshold,
                self.confidenceThresholdName: self.confidenceThreshold,
            ]
        )

        let start = ContinuousClock.now
        let result = try self.model.prediction(from: input)
        let duration = start.duration(to: .now)

        return (result, duration)
    }

    private func decodeResult(_ result: MLFeatureProvider) -> [Detection] {
        guard
            let coordinates = result.featureValue(for: "coordinates")?.multiArrayValue,
            let confidence = result.featureValue(for: "confidence")?.multiArrayValue
        else { preconditionFailure() }
        let numDet = coordinates.shape[0].intValue
        let numCls = confidence.shape[1].intValue

        return (0..<numDet)
            .map { i in
                let cx = coordinates[[i as NSNumber, 0]].doubleValue
                let cy = coordinates[[i as NSNumber, 1]].doubleValue
                let w = coordinates[[i as NSNumber, 2]].doubleValue
                let h = coordinates[[i as NSNumber, 3]].doubleValue
                let bbox = CGRect(x: cx - w / 2, y: 1 - cy - h / 2, width: w, height: h)

                let scores = confidence.dataPointer
                    .advanced(by: i * numCls * MemoryLayout<Double>.stride)
                    .bindMemory(to: Double.self, capacity: numCls)
                let (id, score) = argmax(scores, count: numCls)

                return Detection(id: id, confidence: score, bbox: bbox)
            }
    }
}

extension ObjectDetectionViewState: ObservableObject {}

extension ObjectDetectionViewState: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let (result, duration) = try? self.inference(imageBuffer: frame.capturedImage) else {
            preconditionFailure()
        }
        let detections = self.decodeResult(result)
        self.frameData = .init(detections: detections, inferenceTime: duration)
    }
}
