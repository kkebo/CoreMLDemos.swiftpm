import Accelerate

func argmax(_ array: UnsafePointer<Double>, count: UInt) -> (id: Int, confidence: Double) {
    var maxValue: Double = 0
    var maxIndex: UInt = 0
    vDSP_maxviD(array, 1, &maxValue, &maxIndex, count)
    return (Int(maxIndex), maxValue)
}
