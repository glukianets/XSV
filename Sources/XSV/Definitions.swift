import Swift

// MARK: - SegmentationStrategy

public protocol SegmentationStrategy {
    static var separator: UTF8.CodeUnit { get }
}

// MARK: - SegmentProtocol

public protocol SegmentProtocol: UnitProtocol {
    associatedtype Element: UnitProtocol
}

extension SegmentProtocol {
    fileprivate static var subSegmentType: (any SegmentProtocol.Type)? { Element.self as? any SegmentProtocol.Type }
}

// MARK: - UnitProtocol

public protocol UnitProtocol: Hashable & LosslessStringConvertible {
    associatedtype Strategy: SegmentationStrategy

    init(memento: Memento<Self>)
    var value: Substring { get set }
}

extension UnitProtocol {
    public var description: String {
        get { String(self.value) }
        set { self.value = newValue[...] }
    }
}

extension UnitProtocol {
    private static var strategyType: SegmentationStrategy.Type { Strategy.self }

    private static  var strategies: some Sequence<SegmentationStrategy.Type> {
        sequence(first: Self.self as any UnitProtocol.Type) { current in
            (current as? any SegmentProtocol.Type)?.subSegmentType
        }.map { $0.strategyType }
    }
    
    internal static func segmentator(_ string: Substring) -> Segmentator {
        Segmentator(string, strategies: strategies.reversed())
    }
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
