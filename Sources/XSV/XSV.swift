import Swift

public struct XSVPackageStrategy: SegmentationStrategy {
    public static let separator: UTF8.CodeUnit = 0x1C // 28 - File Separator
}

public struct XSVFileStrategy: SegmentationStrategy {
    public static let separator: UTF8.CodeUnit  = 0x1D // 29 - Group Separator
}

public struct XSVGroupStrategy: SegmentationStrategy {
    public static let separator: UTF8.CodeUnit  = 0x1E // 30 - Record Separator
}

public struct XSVRecordStrategy: SegmentationStrategy {
    public static let separator: UTF8.CodeUnit  = 0x1F // 31 - Unit (Field) Separator
}

public struct XSVUnitStrategy: SegmentationStrategy {
    public static let separator: UInt8 = 0
}

public typealias XSV = Segment<XSVPackageStrategy, XSVFile>
public typealias XSVFile = Segment<XSVFileStrategy, XSVGroup>
public typealias XSVGroup = Segment<XSVGroupStrategy, XSVRecord>
public typealias XSVRecord = Segment<XSVRecordStrategy, Unit>
