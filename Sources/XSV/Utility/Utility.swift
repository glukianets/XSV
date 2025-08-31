import Foundation

internal enum ASCIISeparator: UInt8, Hashable & Comparable & CaseIterable {
    case fs = 0x1C // 28 - File Separator
    case gs = 0x1D // 29 - Group Separator
    case rs = 0x1E // 30 - Record Separator
    case us = 0x1F // 31 - Unit (Field) Separator
    
    public static var allCases: ClosedRange<ASCIISeparator> { .fs ... .us }
    
    public static func < (lhs: ASCIISeparator, rhs: ASCIISeparator) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    internal init?(_ numeric: some BinaryInteger) {
        self.init(rawValue: numericCast(numeric))
    }
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
