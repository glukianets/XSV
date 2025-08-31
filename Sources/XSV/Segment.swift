import Foundation

public struct Segment<let Separator: Int, Element: _SegmentProtocol>: _SegmentProtocol {
    fileprivate enum Value: Hashable {
        case materialized(Element)
        case thunk(data: Substring, RangeData)
    }
    
    private static var separatorString: String {
        String(Character(UnicodeScalar(Separator)!))
    }

    public var value: Substring {
        get {
            self.elements.map {
                switch $0 {
                case .materialized(let segment):
                    segment.value
                case .thunk(data: let substring, _):
                    substring
                }
            }.joined(separator: Self.separatorString)[...]
        }
        set {
            self = .init(newValue)
        }
    }

    private var elements: [Value]
    
    fileprivate init(_ elements: some Sequence<Value>) {
        precondition(ASCIISeparator(Separator) != nil, "Segment Separator has to belong to ASCII IS range")
        self.elements = Array(elements)
    }
    
    public init(memento: Memento) {
        self.init(memento.value.isEmpty ? [] : memento.ranges.ranges.map { .thunk(data: memento.value[$0.range], $0.value) })
    }
}

extension Segment {
    public init(_ string: some StringProtocol) {
        let string = String(string)[...]
        let ranges = RangeData(in: string, separators: ASCIISeparator.allCases)
        self.init(memento: .init(_value: string, _ranges: ranges))
    }
}

extension Segment: RangeReplaceableCollection, RandomAccessCollection, MutableCollection {
    public typealias SubSequence = Slice<Self>
    public typealias Element = Element
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

extension Segment: ExpressibleByArrayLiteral {
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
