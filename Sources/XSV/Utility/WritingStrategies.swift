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
