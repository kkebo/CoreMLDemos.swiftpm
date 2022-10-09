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
    var fps: Double
}

@MainActor
final class ObjectDetectionViewState: NSObject {
    @Published var frameData: FrameData?

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
        self.model = try! MLModel(
            contentsOf: MLModel.compileModel(
                at: Bundle.main.url(
                    forResource: "YOLOv3TinyInt8LUT",
                    withExtension: "mlmodel"
                )!
            ),
            configuration: self.modelConfiguration
        )
        self.imageConstraint = self.model.modelDescription
            .inputDescriptionsByName[self.inputName]!
            .imageConstraint!

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
    ) throws -> (result: MLFeatureProvider, duration: Double) {
        var cgImage: CGImage!
        VTCreateCGImageFromCVPixelBuffer(imageBuffer, options: nil, imageOut: &cgImage)
        
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
        
        let start = Date.now
        let result = try self.model.prediction(from: input)
        let duration = Date.now.timeIntervalSince(start)
        
        return (result, duration)
    }

    private func decodeResult(_ result: MLFeatureProvider) -> [Detection] {
        let coordinates = result.featureValue(for: "coordinates")!.multiArrayValue!
        let confidence = result.featureValue(for: "confidence")!.multiArrayValue!
        let numDet = coordinates.shape[0].intValue
        
        let detections: [Detection] = (0..<numDet).map { i in
            let cx = coordinates[[i as NSNumber, 0]].doubleValue
            let cy = coordinates[[i as NSNumber, 1]].doubleValue
            let w = coordinates[[i as NSNumber, 2]].doubleValue
            let h = coordinates[[i as NSNumber, 3]].doubleValue
            let bbox = CGRect(x: cx - w / 2, y: 1 - cy - h / 2, width: w, height: h)
            
            let numCls = confidence.shape[1].uintValue
            let featurePointer = UnsafePointer<Double>(
                OpaquePointer(confidence.dataPointer.advanced(by: i))
            )
            let (id, conf) = argmax(featurePointer, count: numCls)
            
            return Detection(id: id, confidence: conf, bbox: bbox)
        }
        
        return detections
    }
}

extension ObjectDetectionViewState: ObservableObject {}

extension ObjectDetectionViewState: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let (result, duration) = try! self.inference(imageBuffer: frame.capturedImage)
        let detections = self.decodeResult(result)
        self.frameData = .init(detections: detections, fps: 1 / duration)
    }
}
