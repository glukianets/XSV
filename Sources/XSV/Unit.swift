import Foundation

public struct Unit: _SegmentProtocol {
    public var value: Substring
    
    public init(memento: Memento) {
        self.value = memento.value
    }
    
    public subscript<T: LosslessStringConvertible>(_ type: T.Type = T.self) -> T? {
        get { T.init(self.description) }
        set { self.description = newValue?.description ?? "" }
    }
}

extension Unit {
    public init(_ string: some StringProtocol) {
        let string = String(string)[...]
        self.init(memento: .init(_value: string, _ranges: .init()))
    }
}

extension Unit: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension Unit: Hashable & Equatable { }
