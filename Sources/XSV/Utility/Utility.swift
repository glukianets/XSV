import Swift

infix operator ??=: AssignmentPrecedence

@discardableResult
@inline(__always)
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
