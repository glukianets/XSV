import Swift

// MARK: - SegmentationAction

public enum SegmentationAction {
    case none
    case cut
}

// MARK: - SegmentationStrategy

public protocol SegmentationStrategy {
    static var separator: String { get }

    init()
    mutating func step(_ string: borrowing Substring) -> SegmentationAction
    mutating func resetForNewSegment()
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

    // Build the strategy chain from innermost (Self) up the hierarchy by following Element types,
    // then reverse to have strategies ordered from inner to outer for the Segmentator.
    private static var strategyTypes: [SegmentationStrategy.Type] {
        Array(
            sequence(first: Self.self as any UnitProtocol.Type) { current in
                (current as? any SegmentProtocol.Type)?.subSegmentType
            }.map { $0.strategyType }
        )
    }

    internal static func segmentator(_ string: Substring) -> Segmentator {
        // Instantiate strategies and reverse to match previous Segmentator expectation (outermost last).
        let instances: [any SegmentationStrategy] = Self.strategyTypes.reversed().map { $0.init() }
        return Segmentator(string, strategies: instances)
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

