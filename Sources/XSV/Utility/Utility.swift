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

@inline(__always)
func firstIndexOfDivergence<L: Collection, R: Collection>(
    _ lhs: L,
    _ rhs: R,
    predicate: (L.Element, R.Element) throws -> Bool
) rethrows -> (L.Index, R.Index) {
    var li = lhs.startIndex, ri = rhs.startIndex
    while li < lhs.endIndex, ri < rhs.endIndex, try predicate(lhs[li], rhs[ri]) {
        lhs.formIndex(after: &li)
        rhs.formIndex(after: &ri)
    }
    return (li, ri)
}

extension Collection {
    @inline(__always)
    func indexOfPrefix<R>(_ rhs: R) -> (Self.Index, partial: Bool)?
    where R: Collection, R.Element == Self.Element, Self.Element: Comparable {
        let (li, ri) = firstIndexOfDivergence(self, rhs, predicate: ==)
        return ri < rhs.endIndex ? li >= self.endIndex ? (li, true) : nil : (li, false)
    }
}
