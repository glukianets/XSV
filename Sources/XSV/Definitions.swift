import Swift

// MARK: - SegmentStrategy Supplementaries

public struct SegmentParsingOptions {
    public let isAtEnd: Bool
    
    internal init(isAtEnd: Bool) {
        self.isAtEnd = isAtEnd
    }
}

public enum SegmentationAction {
    case cut(before: String.Index, consumingUntil: String.Index)
    case consume(through: String.Index)
    case buffer
}

public struct ReadingStrategyOptions: OptionSet & Sendable {
    public typealias RawValue = UInt64
    
    public static let `default`: Self = .init(rawValue: 0)

    public static let transient: Self = .init(rawValue: 1 << 0)
    
    public static let skipsEmptyAtStart: Self = .init(rawValue: 1 << 3)
    public static let skipsEmptyInTheMiddle: Self = .init(rawValue: 1 << 2)
    public static let skipsEmptyAtEnd: Self = .init(rawValue: 1 << 1)
    public static let skipsEmpty: Self = [.skipsEmptyAtStart, .skipsEmptyInTheMiddle, .skipsEmptyAtEnd]

    public let rawValue: RawValue
    
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
}

public protocol ReadingStrategyProtocol {
    var options: ReadingStrategyOptions { get }
    mutating func parse(_ string: borrowing Substring, options: SegmentParsingOptions) -> SegmentationAction?
    mutating func resetForNewSegment()
}

extension ReadingStrategyProtocol {
    public var options: ReadingStrategyOptions { .default }
    
    public mutating func resetForNewSegment() { /* nothing */ }
    public mutating func parse(
        _ string: borrowing Substring,
        options: SegmentParsingOptions
    ) -> SegmentationAction? { nil }
}

public protocol WritingStrategyProtocol {
    mutating func openSegment() -> String?
    mutating func closeSegment() -> String?

    mutating func openElement() -> String?
    mutating func closeElement() -> String?

    mutating func processElement(_ contents: consuming String) -> String?
}

extension WritingStrategyProtocol {
    public func openSegment() -> String? { nil }
    public func closeSegment() -> String? { nil }

    public func openElement() -> String? { nil }
    public func closeElement() -> String? { nil }

    public func processElement(_ contents: consuming String) -> String? { contents }
}

// MARK: - SegmentStrategy

public protocol SegmentStrategy {
    associatedtype Value: Hashable
    associatedtype ReadingStrategy: ReadingStrategyProtocol
    associatedtype WritingStrategy: WritingStrategyProtocol

    static func rehydrate(_ memento: Memento<Value>) -> Value
    static func dehydrate(_ value: Value, into: inout some TextOutputStream)
    
    static func readingStrategy() -> ReadingStrategy
    static func writingStrategy() -> WritingStrategy
}

extension SegmentStrategy {
    fileprivate static var strategyTypes: some Sequence<any SegmentStrategy.Type> {
        func next(of type: (some SegmentStrategy).Type) -> (any SegmentStrategy.Type)? {
            (type.Value as? any SegmentProtocol.Type)?.strategyType
        }
        return sequence(first: Self.self) { next(of: $0.self) }
    }
    
    internal static func segmenter(_ string: Substring) -> Segmenter<StringProvider> {
        Segmenter(wrapping: StringProvider(string), strategies: Self.strategyTypes.reversed().map { $0.readingStrategy() })
    }
}

extension SegmentStrategy {
    public static func rehydrate(_ memento: Memento<Value>) -> Value where Value: SegmentProtocol {
        return Value.init(memento: memento)
    }

    public static func dehydrate(_ value: Value, into stream: inout some TextOutputStream) where Value: TextOutputStreamable {
        value.write(to: &stream)
    }
}

// MARK: - SegmentProtocol

public protocol SegmentProtocol: Hashable & ExpressibleByArrayLiteral & LosslessStringConvertible {
    associatedtype Strategy: SegmentStrategy

    init(memento: Memento<Self>)
}

extension SegmentProtocol {
    fileprivate static var strategyType: any SegmentStrategy.Type { Self.Strategy.self }
}

// MARK: - Memento

public struct Memento<Value>: Hashable {
    internal var value: Substring
    internal var ranges: RangeData
    
    internal init(value: Substring, ranges: RangeData) {
        self.value = value
        self.ranges = ranges
    }
    
    public init(_ string: some StringProtocol) where Value: SegmentProtocol {
        let substring = Substring(string)
        let ranges = RangeData(segmentator: Value.Strategy.segmenter(substring))
        self.init(value: substring, ranges: ranges)
    }
    
    internal func transmute<R>() -> Memento<R> {
        return .init(value: self.value, ranges: self.ranges)
    }
}

