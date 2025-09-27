import Swift

// MARK: - SeparatorWritingStrategy

internal struct SeparatorWritingStrategy: WritingStrategyProtocol {
    private let separator: String
    private var hadPreviousElement: Bool = false
    
    public init(separator: String) {
        self.separator = separator
    }
    
    public mutating func openElement() -> String? {
        guard self.hadPreviousElement else { self.hadPreviousElement = true; return nil }
        return self.separator
    }
}

// MARK: - LineWritingStrategy

internal struct LineWritingStrategy: WritingStrategyProtocol {
    public struct Separator: OptionSet {
        public let rawValue: UInt8
        
        public static let cr: Separator = .init(rawValue: 0xD)
        public static let lf: Separator = .init(rawValue: 0xA)
        
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
    }
    
    private let separator: String
    
    public init(separator: Separator) {
        self.separator = (separator.contains(Separator.cr) ? "\r" : "") + (separator.contains(Separator.lf) ? "\n" : "")
    }
    
    public mutating func closeElement() -> String? {
        self.separator
    }
}
