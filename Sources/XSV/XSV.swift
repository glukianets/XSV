import Swift

public typealias XSV = Segment<XSVPackageStrategy>
public typealias XSVFile = Segment<XSVFileStrategy>
public typealias XSVGroup = Segment<XSVGroupStrategy>
public typealias XSVRecord = Segment<XSVRecordStrategy>
public typealias XSVUnit = Segment<XSVUnitStrategy>

internal protocol SeparatorSegmentationStrategy: SegmentationStrategy {
    static var separator: String { get }
}

extension SeparatorSegmentationStrategy {
    public mutating func step(_ segment: borrowing Substring) -> SegmentationAction? {
        return segment.range(of: Self.separator, options: .anchored)
            .map(\.upperBound)
            .map(SegmentationAction.cut(before:))
    }
    
    public mutating func resetForNewSegment() { }
    
    public static func merge(_ elements: some Sequence<Substring>) -> Substring {
        elements.joined(separator: Self.separator)[...]
    }
}

public struct XSVPackageStrategy: SeparatorSegmentationStrategy {
    public typealias Next = XSVFileStrategy
    
    public static let separator = "\u{1C}"// 28 - File Separator
    
    public init() { }
}

public struct XSVFileStrategy: SeparatorSegmentationStrategy {
    public typealias Next = XSVGroupStrategy

    public static let separator = "\u{1D}" // 29 - Group Separator
    
    public init() { }
}

public struct XSVGroupStrategy: SeparatorSegmentationStrategy {
    public typealias Next = XSVRecordStrategy

    public static let separator = "\u{1E}" // 30 - Record Separator
    
    public init() { }
}

public struct XSVRecordStrategy: SeparatorSegmentationStrategy {
    public typealias Next = XSVUnitStrategy
    public typealias Value = Unit<XSVUnitStrategy>
    
    public static let separator = "\u{1F}" // 31 - Unit (Field) Separator
    
    public init() { }
}

public struct XSVUnitStrategy: UnitStrategy {
    public typealias Value = Never
    
    public init() { }

    public mutating func step(_ segment: borrowing Substring) -> SegmentationAction? {
        return .none
    }

    public mutating func resetForNewSegment() { }
    
    public static func merge(_ elements: some Sequence<Substring>) -> Substring {
        elements.joined(separator: "")[...]
    }
}
