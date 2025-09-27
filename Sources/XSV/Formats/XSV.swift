import Foundation

public typealias XSV = Segment<XSVFileStrategy>
public typealias XSVFile = Segment<XSVGroupStrategy>
public typealias XSVGroup = Segment<XSVRecordStrategy>
public typealias XSVRecord = Segment<XSVUnitStrategy>
public typealias XSVUnit = String

internal protocol SeparatorSegmentationStrategy: SegmentStrategy {
    static var separator: String { get }
    static var isEphemeral: Bool { get }
}

extension SeparatorSegmentationStrategy {
    public static var isEphemeral: Bool {
        true
    }
    
    public static func readingStrategy() -> SeparatorParserStrategy {
        .init(separator: Self.separator, options: self.isEphemeral ? .transient : .default)
    }
    
    public static func writingStrategy() -> SeparatorWritingStrategy {
        .init(separator: Self.separator)
    }
}

public struct XSVFileStrategy: SeparatorSegmentationStrategy {
    public typealias Value = Segment<XSVGroupStrategy>
    
    internal static let separator = "\u{1C}"// 28 - File Separator
}

public struct XSVGroupStrategy: SeparatorSegmentationStrategy {
    public typealias Value = Segment<XSVRecordStrategy>

    internal static let separator = "\u{1D}" // 29 - Group Separator
}

public struct XSVRecordStrategy: SeparatorSegmentationStrategy {
    public typealias Value = Segment<XSVUnitStrategy>

    internal static let separator = "\u{1E}" // 30 - Record Separator
}

public struct XSVUnitStrategy: SeparatorSegmentationStrategy {
    public typealias Value = String
    
    internal static let separator = "\u{1F}" // 31 - Unit (Field) Separator
    internal static let isEphemeral: Bool = false
    
    public static func rehydrate(_ memento: Memento<Value>) -> String {
        String(memento.value)
    }
}
