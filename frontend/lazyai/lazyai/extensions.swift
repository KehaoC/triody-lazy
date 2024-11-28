import SwiftUI

typealias CGOffset = CGSize

extension CGOffset {
    static func + (lhs: CGOffset, rhs: CGOffset)->CGOffset {
        return CGOffset(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }

    static func += (lhs: inout CGOffset, rhs: CGOffset) {
        lhs = lhs + rhs
    }
}
