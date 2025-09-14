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
    public mutating func step(_ segment: borrowing Substring) -> SegmentationAction? {
        return segment.range(of: Self.separator, options: .anchored)
            .map(\.upperBound)
            .map(SegmentationAction.cut(before:))
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

    public mutating func step(_ segment: borrowing Substring) -> SegmentationAction? {
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
