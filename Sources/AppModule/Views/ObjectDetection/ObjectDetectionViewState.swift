import ARKit
import CoreML
import Observation
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

@Observable
final class ObjectDetectionViewState: NSObject {
    var frameData: FrameData? = nil
    var renderingTime: Duration? = nil

    // ML model
    var model: MLModel? = nil
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
    var imageConstraint: MLImageConstraint? = nil
    let imageOptions: [MLFeatureValue.ImageOption: Any] = [
        .cropAndScale: VNImageCropAndScaleOption.scaleFill
    ]

    var isLoading: Bool { self.model == nil }

    func loadModel() async throws {
        guard
            let url = Bundle.main.url(
                forResource: "YOLOv3TinyInt8LUT",
                withExtension: "mlmodel"
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
        self.imageConstraint = imageConstraint
    }

    private func inference(
        model: MLModel,
        imageConstraint: MLImageConstraint,
        imageBuffer: CVPixelBuffer
    ) throws -> (result: MLFeatureProvider, duration: Duration) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(imageBuffer, options: nil, imageOut: &cgImage)
        guard let cgImage else { preconditionFailure() }

        let featureValue = try MLFeatureValue(
            cgImage: cgImage,
            constraint: imageConstraint,
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
        let result = try model.prediction(from: input)
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

extension ObjectDetectionViewState: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let model, let imageConstraint else { return }
        guard
            let (result, duration) = try? self.inference(
                model: model,
                imageConstraint: imageConstraint,
                imageBuffer: frame.capturedImage
            )
        else { preconditionFailure() }
        let detections = self.decodeResult(result)
        self.frameData = .init(detections: detections, inferenceTime: duration)
    }
}
