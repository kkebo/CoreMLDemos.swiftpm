import Accelerate

func argmax(_ arrayPtr: UnsafePointer<Double>, count: Int) -> (id: Int, confidence: Double) {
    var maxValue: Double = 0
    var maxIndex: UInt = 0
    vDSP_maxviD(arrayPtr, 1, &maxValue, &maxIndex, UInt(count))
    return (Int(maxIndex), maxValue)
}
