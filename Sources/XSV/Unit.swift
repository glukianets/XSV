import Foundation

public struct Unit: UnitProtocol {
    public typealias Strategy = XSVUnitStrategy
    
    public var value: Substring
    
    public init(memento: Memento<Self>) {
        self.value = memento.value
    }
    
    public subscript<T: LosslessStringConvertible>(_ type: T.Type = T.self) -> T? {
        get { T.init(self.description) }
        set { self.description = newValue?.description ?? "" }
    }
}

extension Unit {
    public static func memento(_ string: some StringProtocol) -> Memento<Self> {
        return .init(_value: Substring(string), _ranges: .init())
    }
    
    public init(_ string: some StringProtocol) {
        self.init(memento: Self.memento(string))
    }
}

extension Unit: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension Unit: Hashable & Equatable { }
