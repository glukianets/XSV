import Foundation

infix operator ??=: NilCoalescingPrecedence

@discardableResult
internal func ??=<T>(_ lhs: inout T?, _ rhs: @autoclosure () -> T?) -> T? {
    guard lhs == nil else { return lhs }
    defer { lhs = rhs() }
    return lhs
}

extension Range where Bound: Strideable, Bound.Stride == Bound {
    internal func rebased(relativeTo parent: Range<Bound>) -> Range<Bound> {
        let clamped = self.clamped(to: parent)
        let start = parent.lowerBound.distance(to: clamped.lowerBound)
        let end = parent.lowerBound.distance(to: clamped.upperBound)
        return start..<end
    }
}

extension Data {
    internal func sanitized(erasingSeparators range: Range<UInt8>) -> Self {
        var copy = self
        
        copy.withUnsafeMutableBytes { buffer in
            for i in stride(from: 0, to: buffer.count, by: 1) {
                if range.contains(buffer[i]) {
                    buffer[i] = 0xFF
                }
            }
        }
        
        return copy
    }
}
