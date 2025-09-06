import Swift

public typealias XSV = Segment<XSVPackageStrategy, XSVFile>
public typealias XSVFile = Segment<XSVFileStrategy, XSVGroup>
public typealias XSVGroup = Segment<XSVGroupStrategy, XSVRecord>
public typealias XSVRecord = Segment<XSVRecordStrategy, Unit>

public struct XSVPackageStrategy: SegmentationStrategy {
    public static let separator = "\u{1C}"// 28 - File Separator
    
    public init() { }
    
    public mutating func step(_ segment: borrowing Substring) -> SegmentationAction? {
        return segment.range(of: Self.separator, options: .anchored)
            .map(\.upperBound)
            .map(SegmentationAction.cut(before:))
    }
    
    public mutating func resetForNewSegment() { }
}

public struct XSVFileStrategy: SegmentationStrategy {
    public static let separator = "\u{1D}" // 29 - Group Separator
    
    public init() { }
    
    public mutating func step(_ segment: borrowing Substring) -> SegmentationAction? {
        return segment.range(of: Self.separator, options: .anchored)
            .map(\.upperBound)
            .map(SegmentationAction.cut(before:))
    }
    
    public mutating func resetForNewSegment() { }
}

public struct XSVGroupStrategy: SegmentationStrategy {
    public static let separator = "\u{1E}" // 30 - Record Separator
    
    public init() { }
    
    public mutating func step(_ segment: borrowing Substring) -> SegmentationAction? {
        return segment.range(of: Self.separator, options: .anchored)
            .map(\.upperBound)
            .map(SegmentationAction.cut(before:))
    }
    
    public mutating func resetForNewSegment() { }
}

public struct XSVRecordStrategy: SegmentationStrategy {
    public static let separator = "\u{1F}" // 31 - Unit (Field) Separator
    
    public init() { }

    public mutating func step(_ segment: borrowing Substring) -> SegmentationAction? {
        return segment.range(of: Self.separator, options: .anchored)
            .map(\.upperBound)
            .map(SegmentationAction.cut(before:))
    }

    public mutating func resetForNewSegment() { }
}

public struct XSVUnitStrategy: SegmentationStrategy {
    public static let separator = "\u{0}"
    
    public init() { }

    public mutating func step(_ segment: borrowing Substring) -> SegmentationAction? {
        return .none
    }

    public mutating func resetForNewSegment() { }
}
