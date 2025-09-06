import Foundation

public struct Segment<Strategy: UnitStrategy>: UnitProtocol {
    public typealias Strategy = Strategy
    public typealias Element = Strategy.Value

    fileprivate enum Storage: Hashable {
        case materialized(Strategy.Value)
        case thunk(data: Substring, RangeData)
    }
    
    public var value: Substring {
        get {
            Strategy.merge(self.elements.map { e -> Substring in
                switch e {
                case .materialized(let segment):
                    segment.value
                case .thunk(data: let substring, _):
                    substring
                }
            })
        }
        set {
            self = .init(newValue)
        }
    }

    private var elements: [Storage]
    
    fileprivate init(_ elements: some Sequence<Storage>) {
        self.elements = Array(elements)
    }
    
    public init(memento: Memento<Self>) {
        self.init(
            memento.value.isEmpty ? [] : memento.ranges.ranges.map { .thunk(data: memento.value[$0.range], $0.value) }
        )
    }
}

extension Segment: SegmentProtocol where Self.Strategy: SegmentationStrategy { }

extension Segment {
    public static func memento(_ string: some StringProtocol) -> Memento<Self> {
        let string = Substring(string)
        let ranges = RangeData(segmentator: Self.Strategy.segmentator(string))
        return .init(_value: string, _ranges: ranges)
    }
    
    public init(_ string: some StringProtocol) {
        self.init(memento: Self.memento(string))
    }
}

extension Segment: Sequence & Collection & BidirectionalCollection & RangeReplaceableCollection & RandomAccessCollection & MutableCollection where Self: SegmentProtocol {
    public typealias SubSequence = Slice<Self>
    public typealias Index = Int

    public var startIndex: Int { elements.startIndex }
    public var endIndex: Int { elements.endIndex }

    public func index(after i: Int) -> Int { elements.index(after: i) }
    public func index(before i: Int) -> Int { elements.index(before: i) }

    public subscript(position: Int) -> Element {
        get {
            switch self.elements[position] {
            case .materialized(let element):
                return element
            case .thunk(data: let data, let ranges):
                return Element(memento: Memento(_value: data, _ranges: ranges))
            }
        }
        set { self.elements[position] = .materialized(newValue) }
    }

    public subscript(bounds: Range<Int>) -> Slice<Self> {
        get { Slice(base: self, bounds: bounds) }
        set { self.replaceSubrange(bounds, with: newValue) }
    }

    public init() {
        self.init([])
    }

    public mutating func replaceSubrange<C>(
        _ subrange: Range<Int>,
        with newElements: C
    ) where C: Collection, C.Element == Element {
        self.elements.replaceSubrange(subrange, with: newElements.map { .materialized($0) })
    }
}

extension Segment: ExpressibleByArrayLiteral where Self: SegmentProtocol {
    public typealias ArrayLiteralElement = Element
    
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}

extension Segment: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension Segment: Hashable & Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        zip(lhs.elements, rhs.elements).allSatisfy(==)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.elements)
    }
}
