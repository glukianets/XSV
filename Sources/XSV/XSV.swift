import Swift

public typealias XSV = Segment<XSVPackageStrategy, XSVFile>
public typealias XSVFile = Segment<XSVFileStrategy, XSVGroup>
public typealias XSVGroup = Segment<XSVGroupStrategy, XSVRecord>
public typealias XSVRecord = Segment<XSVRecordStrategy, Unit>

public struct XSVPackageStrategy: SegmentationStrategy {
    public static let separator: UTF8.CodeUnit = 0x1C // 28 - File Separator
    
    public init() { }
    
    public mutating func step(byte: UInt8) -> SegmentationAction {
        return byte == Self.separator ? .cut : .none
    }
    
    public mutating func resetForNewSegment() { }
}

public struct XSVFileStrategy: SegmentationStrategy {
    public static let separator: UTF8.CodeUnit  = 0x1D // 29 - Group Separator

    public init() { }
    
    public mutating func step(byte: UInt8) -> SegmentationAction {
        return byte == Self.separator ? .cut : .none
    }
    
    public mutating func resetForNewSegment() { }
}

public struct XSVGroupStrategy: SegmentationStrategy {
    public static let separator: UTF8.CodeUnit  = 0x1E // 30 - Record Separator

    public init() { }
    
    public mutating func step(byte: UInt8) -> SegmentationAction {
        return byte == Self.separator ? .cut : .none
    }
    
    public mutating func resetForNewSegment() { }
}

public struct XSVRecordStrategy: SegmentationStrategy {
    public static let separator: UTF8.CodeUnit  = 0x1F // 31 - Unit (Field) Separator

    public init() { }

    public mutating func step(byte: UInt8) -> SegmentationAction {
        return byte == Self.separator ? .cut : .none
    }

    public mutating func resetForNewSegment() { }
}

public struct XSVUnitStrategy: SegmentationStrategy {
    public static let separator: UInt8 = 0

    public init() { }

    public mutating func step(byte: UInt8) -> SegmentationAction {
        return .none
    }

    public mutating func resetForNewSegment() { }
}
