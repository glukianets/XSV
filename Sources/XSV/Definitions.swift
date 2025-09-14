import Swift

// MARK: - SegmentationAction

public enum SegmentationAction {
    case cut(before: String.Index)
    case consume(through: String.Index)
}

// MARK: - UnitStrategy

public protocol UnitStrategy {
    init()
    mutating func step(_ string: borrowing Substring) -> SegmentationAction?
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
        func next(of type: (some SegmentationStrategy).Type) -> any UnitStrategy.Type { type.Value.Strategy.self }
        return sequence(first: Self.self) { ($0 as? any SegmentationStrategy.Type).map { next(of: $0) } }
    }
    
    internal static func segmentator(_ string: Substring) -> Segmentator {
        Segmentator(string, strategies: Self.strategyTypes.reversed().map { $0.init() })
    }
}

// MARK: - SegmentationStrategy

public protocol SegmentationStrategy: UnitStrategy {
    associatedtype Value: UnitProtocol
    
    static func join(_ elements: some Sequence<Value>) -> Substring
    static func split(_ value: Substring) -> Memento<Self>
}

extension SegmentationStrategy {
    public static func split(_ string: Substring) -> Memento<Self> {
        guard !string.isEmpty else { return .init(_value: Substring(), _ranges: .init()) }
        let ranges = RangeData(segmentator: Self.segmentator(string))
        return .init(_value: string, _ranges: ranges)
    }
}

// MARK: - SegmentProtocol

public protocol SegmentProtocol: UnitProtocol & ExpressibleByArrayLiteral {
    associatedtype Element: UnitProtocol
}

extension SegmentProtocol {
    fileprivate static var subSegmentType: (any SegmentProtocol.Type)? { Element.self as? any SegmentProtocol.Type }
}

// MARK: - UnitProtocol

public protocol UnitProtocol: Hashable & LosslessStringConvertible & RawRepresentable where RawValue == Substring {
    associatedtype Strategy: UnitStrategy

    var rawValue: Substring { get set }
    init(memento: Memento<Self.Strategy>)
}

// MARK: - Value

extension Never: @retroactive LosslessStringConvertible {}
extension Never: @retroactive CustomStringConvertible {}
extension Never: @retroactive RawRepresentable {}
extension Never: UnitProtocol & UnitStrategy {
    public typealias Value = Never
    
    public init() { fatalError() }
    
    public mutating func step(_ string: borrowing Substring) -> SegmentationAction? { fatalError() }
    
    public mutating func resetForNewSegment() { fatalError() }
    
    public static func merge(_ elements: some Sequence<Substring>) -> Substring { fatalError() }
    
    public typealias Strategy = Never
    
    public init(memento: Memento<Never>) { fatalError() }
    
    public var rawValue: Substring {
        get { fatalError() }
        set { fatalError() }
    }
    
    public init(_ description: String) { fatalError() }
    
    public var description: String { fatalError() }
    
    public init(rawValue: Substring) { fatalError() }
}

// MARK: - Memento

public struct Memento<T: UnitStrategy>: Hashable {
    internal var value: Substring
    internal var ranges: RangeData
    
    internal init(_value: Substring, _ranges: RangeData) {
        self.value = _value
        self.ranges = _ranges
    }
}

