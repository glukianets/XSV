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
internal func firstDivergence<L: Collection, R: Collection>(
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
    internal func indexAfter<R>(prefix rhs: R) -> (Self.Index, partial: Bool)?
    where R: Collection, R.Element == Self.Element, Self.Element: Comparable {
        let (li, ri) = firstDivergence(self, rhs, predicate: ==)
        return ri < rhs.endIndex ? li >= self.endIndex ? (li, true) : nil : (li, false)
    }
}
extension Collection {
    @inline(__always)
    internal func firstRange<R>(of rhs: R) -> (Range<Self.Index>, partial: Bool)?
    where R: Collection, R.Element == Self.Element, Self.Element: Comparable {
        for startIndex in self.indices {
            if let next = self[startIndex...].indexAfter(prefix: rhs) {
                return (startIndex..<next.0, next.partial)
            }
        }
        return nil
    }
}

#if canImport(Foundation)

import Foundation

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

#endif // canImport(Foundation)
