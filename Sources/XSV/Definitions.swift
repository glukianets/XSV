import Swift

// MARK: - SegmentationAction

public enum SegmentationAction {
    case cut(before: String.Index)
    case consume(through: String.Index)
}

// MARK: - UnitStrategy

public protocol UnitStrategy {
    associatedtype Value: ValueProtocol
    
    init()
    mutating func step(_ string: borrowing Substring) -> SegmentationAction?
    mutating func resetForNewSegment()
    
    static func merge(_ elements: some Sequence<Substring>) -> Substring
}

extension UnitStrategy {
    private static var strategyTypes: some Sequence<any UnitStrategy.Type> {
        func next(of type: (some SegmentationStrategy).Type) -> any UnitStrategy.Type { type.Next.self }
        return sequence(first: Self.self) { ($0 as? any SegmentationStrategy.Type).map { next(of: $0) } }
    }
    
    internal static func segmentator(_ string: Substring) -> Segmentator {
        Segmentator(string, strategies: Self.strategyTypes.reversed().map { $0.init() })
    }
}

// MARK: - SegmentationStrategy

public protocol SegmentationStrategy: UnitStrategy {
    associatedtype Value: UnitProtocol = Segment<Next> where Value.Strategy == Next
    
    associatedtype Next: UnitStrategy
}

// MARK: - SegmentProtocol

public protocol SegmentProtocol: UnitProtocol & ExpressibleByArrayLiteral {
    associatedtype Element: UnitProtocol
}

extension SegmentProtocol {
    fileprivate static var subSegmentType: (any SegmentProtocol.Type)? { Element.self as? any SegmentProtocol.Type }
}

// MARK: - UnitProtocol

public protocol UnitProtocol: ValueProtocol {
    associatedtype Strategy: UnitStrategy

    init(memento: Memento<Self>)
}

extension UnitProtocol {
    public var description: String {
        get { String(self.value) }
        set { self.value = newValue[...] }
    }
}

// MARK: - Value

public protocol ValueProtocol: Hashable & LosslessStringConvertible {
    var value: Substring { get set }
}

extension ValueProtocol where Self: StringProtocol {
    public var value: Substring {
        get { Substring(self) }
        set { self = Self.init(String(newValue)) ?? self }
    }
}

extension Substring: ValueProtocol {
    public var value: Substring {
        get { self }
        set { self = newValue }
    }
}

extension Never: @retroactive LosslessStringConvertible {}
extension Never: @retroactive CustomStringConvertible {}
extension Never: ValueProtocol {
    public var value: Substring {
        get { fatalError() }
        set { fatalError() }
    }
    
    public init?(_ description: String) { nil }
    
    public var description: String { fatalError() }
}

// MARK: - Memento

public struct Memento<T: UnitProtocol> {
    internal var value: Substring
    internal var ranges: RangeData
    
    internal init(_value: Substring, _ranges: RangeData) {
        self.value = _value
        self.ranges = _ranges
    }
}

