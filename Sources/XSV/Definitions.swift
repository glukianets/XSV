import Swift

// MARK: - SegmentationAction

public enum SegmentationAction {
    case cut(before: String.Index)
    case consume(through: String.Index)
    case buffer
}

// MARK: - UnitStrategy

public struct UnitStrategyParsingOptions {
    public let isAtEnd: Bool
    
    internal init(isAtEnd: Bool) {
        self.isAtEnd = isAtEnd
    }
}

public protocol UnitStrategy {
    init()
    mutating func parse(_ string: borrowing Substring, options: UnitStrategyParsingOptions) -> SegmentationAction?
    mutating func resetForNewSegment()
    
    static func escape(_ value: Substring) -> Substring
    static func unescape(_ value: Substring) -> Substring
}

extension UnitStrategy {
    public static func escape(_ value: Substring) -> Substring { value }
    public static func unescape(_ value: Substring) -> Substring { value }
}

extension UnitStrategy {
    private static var strategyTypes: some Sequence<any UnitStrategy.Type> {
        func next(of type: (some SegmentStrategy).Type) -> any UnitStrategy.Type { type.Value.Strategy.self }
        return sequence(first: Self.self) { ($0 as? any SegmentStrategy.Type).map { next(of: $0) } }
    }
    
    internal static func segmenter(_ string: Substring) -> Segmenter<StringProvider> {
        Segmenter(wrapping: StringProvider(string), strategies: Self.strategyTypes.reversed().map { $0.init() })
    }
}

// MARK: - SegmentationStrategy

public protocol SegmentStrategy: UnitStrategy {
    associatedtype Value: UnitProtocol
    
    static func join(_ elements: some Sequence<Value>) -> Substring
    static func split(_ value: Substring) -> Memento<Self>
}

extension SegmentStrategy {
    public static func split(_ string: Substring) -> Memento<Self> {
        .init(string)
    }
}

// MARK: - SegmentProtocol

public protocol SegmentProtocol: UnitProtocol & ExpressibleByArrayLiteral {
    associatedtype Element: UnitProtocol
}

// MARK: - UnitProtocol

public protocol UnitProtocol: Hashable & LosslessStringConvertible & RawRepresentable where RawValue == Substring {
    associatedtype Strategy: UnitStrategy

    var rawValue: Substring { get set }
    init(memento: Memento<Self.Strategy>)
}

// MARK: - Memento

public struct Memento<Strategy: UnitStrategy>: Hashable {
    internal var value: Substring
    internal var ranges: RangeData
    
    internal init(value: Substring, ranges: RangeData) {
        self.value = value
        self.ranges = ranges
    }
    
    public init(_ string: some StringProtocol) {
        let substring = Substring(string)
        let ranges = RangeData(segmentator: Strategy.segmenter(substring))
        self.init(value: substring, ranges: ranges)
    }
}

