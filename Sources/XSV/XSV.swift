import Foundation

public typealias XSV = Segment<XSVFileStrategy>
public typealias XSVFile = Segment<XSVGroupStrategy>
public typealias XSVGroup = Segment<XSVRecordStrategy>
public typealias XSVRecord = Segment<XSVUnitStrategy>
public typealias XSVUnit = String

public struct SeparatorParserStrategy: ReadingStrategyProtocol {
    private let separator: String
    
    public init(separator: String, options: ReadingStrategyOptions = .default) {
        self.separator = separator
        self.options = options
    }
    
    public var options: ReadingStrategyOptions
    
    public mutating func parse(
        _ segment: borrowing Substring,
        options: SegmentParsingOptions
    ) -> SegmentationAction? {
        guard let (cutIndex, isParital) = segment.utf8.indexOfPrefix(self.separator.utf8) else { return .none }
        guard !isParital else { return options.isAtEnd ? .none : .buffer }
        return .cut(before: segment.startIndex, consumingUntil: cutIndex)
    }
    
    public mutating func resetForNewSegment() { }
}

public struct SeparatorWritingStrategy: WritingStrategyProtocol {
    private let separator: String
    private var hadPreviousElement: Bool = false
    
    public init(separator: String) {
        self.separator = separator
    }
    
    public mutating func openElement() -> String? {
        guard self.hadPreviousElement else { self.hadPreviousElement = true; return nil }
        return self.separator
    }
}

internal protocol SeparatorSegmentationStrategy: SegmentStrategy {
    static var separator: String { get }
}

extension SeparatorSegmentationStrategy {
    public static func readingStrategy() -> SeparatorParserStrategy {
        .init(separator: Self.separator)
    }
    
    public static func writingStrategy() -> SeparatorWritingStrategy {
        .init(separator: Self.separator)
    }
}

public struct XSVFileStrategy: SeparatorSegmentationStrategy {
    public typealias Value = Segment<XSVGroupStrategy>
    
    public static let separator = "\u{1C}"// 28 - File Separator
    
    public init() { }
}

public struct XSVGroupStrategy: SeparatorSegmentationStrategy {
    public typealias Value = Segment<XSVRecordStrategy>

    public static let separator = "\u{1D}" // 29 - Group Separator
    
    public init() { }
}

public struct XSVRecordStrategy: SeparatorSegmentationStrategy {
    public typealias Value = Segment<XSVUnitStrategy>

    public static let separator = "\u{1E}" // 30 - Record Separator
    
    public init() { }
}

public struct XSVUnitStrategy: SeparatorSegmentationStrategy {
    public typealias Value = String
    
    public static let separator = "\u{1F}" // 31 - Unit (Field) Separator
    
    public init() { }
    
    public static func rehydrate(_ memento: Memento<Value>) -> String {
        String(memento.value)
    }
}
