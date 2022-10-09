import UIKit

extension CGImagePropertyOrientation {
    init(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .right
        case .portraitUpsideDown: self = .left
        case .landscapeLeft: self = .down
        case .landscapeRight: self = .up
        case _: self = .right
        }
    }
}
