import Foundation

public typealias XSV = Segment<XSVPackageStrategy>
public typealias XSVFile = Segment<XSVFileStrategy>
public typealias XSVGroup = Segment<XSVGroupStrategy>
public typealias XSVRecord = Segment<XSVRecordStrategy>
public typealias XSVUnit = Unit<XSVUnitStrategy>

internal protocol SeparatorSegmentationStrategy: SegmentStrategy {
    static var separator: String { get }
}

extension SeparatorSegmentationStrategy {
    public mutating func parse(
        _ segment: borrowing Substring,
        options: UnitStrategyParsingOptions
    ) -> SegmentationAction? {
        let segUTF8 = segment.utf8
        let sepUTF8 = Self.separator.utf8
        
        var sIdx = segUTF8.startIndex
        let sEnd = segUTF8.endIndex
        var pIdx = sepUTF8.startIndex
        let pEnd = sepUTF8.endIndex
        
        if pIdx == pEnd { return nil }
        if sIdx == sEnd { return .buffer }
        
        // Fast path for single-byte separator (common here: ASCII control chars).
        let firstByte = sepUTF8[pIdx]
        let pNext = sepUTF8.index(after: pIdx)
        if segUTF8[sIdx] != firstByte {
            return nil
        }
        sIdx = segUTF8.index(after: sIdx)
        if pNext == pEnd {
            return .cut(before: sIdx)
        }
        
        // General path for multi-byte separator.
        pIdx = pNext
        while true {
            if pIdx == pEnd {
                return .cut(before: sIdx)
            }
            if sIdx == sEnd {
                return .buffer
            }
            if segUTF8[sIdx] != sepUTF8[pIdx] {
                return nil
            }
            sIdx = segUTF8.index(after: sIdx)
            pIdx = sepUTF8.index(after: pIdx)
        }
    }
    
    public mutating func resetForNewSegment() { }
    
    public static func join(_ elements: some Sequence<Value>) -> Substring {
        elements.map { $0.rawValue }.joined(separator: Self.separator)[...]
    }
    
    public static func escape(_ value: Substring) -> Substring {
        value
    }
    
    public static func unescape(_ value: Substring) -> Substring {
        value
    }
}

public struct XSVPackageStrategy: SeparatorSegmentationStrategy {
    public typealias Value = Segment<XSVFileStrategy>
    
    public static let separator = "\u{1C}"// 28 - File Separator
    
    public init() { }
}

public struct XSVFileStrategy: SeparatorSegmentationStrategy {
    public typealias Value = Segment<XSVGroupStrategy>

    public static let separator = "\u{1D}" // 29 - Group Separator
    
    public init() { }
}

public struct XSVGroupStrategy: SeparatorSegmentationStrategy {
    public typealias Value = Segment<XSVRecordStrategy>

    public static let separator = "\u{1E}" // 30 - Record Separator
    
    public init() { }
}

public struct XSVRecordStrategy: SeparatorSegmentationStrategy {
    public typealias Value = Unit<XSVUnitStrategy>
    
    public static let separator = "\u{1F}" // 31 - Unit (Field) Separator
    
    public init() { }
}

public struct XSVUnitStrategy: UnitStrategy {
    public init() { }

    public mutating func parse(_ segment: borrowing Substring, options: UnitStrategyParsingOptions) -> SegmentationAction? {
        return .none
    }

    public mutating func resetForNewSegment() { }
    
    public static func merge(_ elements: some Sequence<Substring>) -> Substring {
        elements.joined(separator: "")[...]
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
