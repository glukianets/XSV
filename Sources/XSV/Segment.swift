import Swift

public struct Segment<Strategy: SegmentStrategy>: SegmentProtocol {
    public typealias Strategy = Strategy
    public typealias Element = Strategy.Value

    fileprivate enum Storage: Hashable {
        case materialized(Element)
        case thunk(Memento<Element>)
    }
    
    private var elements: [Storage]
    
    fileprivate init(_ elements: some Sequence<Storage>) {
        self.elements = Array(elements)
    }
    
    public init(memento: Memento<Self>) {
        self.init(
            memento.value.isEmpty ? [] : memento.ranges.ranges.map {
                .thunk(.init(value: $0.segment, ranges: $0.value))
            }
        )
    }
}

extension Segment: LosslessStringConvertible {
    public var description: String {
        var result = ""
        self.write(to: &result)
        return result
    }

    public init(_ description: String) {
        self.init(memento: .init(description))
    }
}

extension Segment: TextOutputStreamable {
    public func write(to target: inout some TextOutputStream) {
        var strategy = Strategy.writingStrategy()
        strategy.withStream(&target) { withElement in
            for element in elements {
                withElement { stream in
                    switch element {
                    case .materialized(let segment):
                        Strategy.dehydrate(segment, into: &stream)
                    case .thunk(let memento):
                        memento.value.write(to: &stream)
                    }
                }
            }
        }
    }
}

extension Segment: RangeReplaceableCollection & RandomAccessCollection & MutableCollection
where Self: SegmentProtocol {
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
                element
            case .thunk(let memento):
                Self.Strategy.rehydrate(memento)
            }
        }
        set {
            self.elements[position] = .materialized(newValue)
        }
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
        lhs.elements.count == rhs.elements.count && zip(lhs.elements, rhs.elements).allSatisfy(==)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.elements)
    }
}
