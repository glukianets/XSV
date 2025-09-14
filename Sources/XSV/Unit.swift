import Swift

public struct Unit<Strategy: UnitStrategy>: UnitProtocol {
    public typealias Strategy = Strategy
    
    private static func memento(_ string: some StringProtocol) -> Memento<Strategy> {
        return .init(_value: Substring(string), _ranges: .init())
    }
    
    public var rawValue: Substring
    
    public var description: String {
        get { String(Self.Strategy.unescape(self.rawValue)) }
        set { self.rawValue = Self.Strategy.escape(newValue[...]) }
    }

    public init(memento: Memento<Strategy>) {
        self.rawValue = memento.value
    }
    
    public subscript<T: LosslessStringConvertible>(_ type: T.Type = T.self) -> T? {
        get { T.init(self.description) }
        set { self.description = newValue?.description ?? "" }
    }
    
    public init(rawValue: Substring) {
        self.init(rawValue)
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
