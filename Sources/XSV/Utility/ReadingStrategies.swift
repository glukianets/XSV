import Swift

// MARK: - LineReadingStrategy

internal struct LineReadingStrategy: ReadingStrategyProtocol {
    public let options: ReadingStrategyOptions
    
    public init(options: ReadingStrategyOptions = [.skipsEmptyAtEnd, .transient]) {
        self.options = options
    }
    
    public mutating func parse(
        _ string: borrowing Substring,
        options: SegmentParsingOptions
    ) -> SegmentationAction? {
        let CR: UInt8 = 0x0D
        let LF: UInt8 = 0x0A
        
        let bytes = string.utf8
        switch bytes.first {
        case CR:
            var index = bytes.index(after: bytes.startIndex)
            if index < bytes.endIndex && bytes[index] == LF {
                bytes.formIndex(after: &index)
            }
            if index >= bytes.endIndex {
                // The last newline is skipped since it doesn't denote an element separator
                return options.isAtEnd ? .cut(before: string.startIndex, consumingUntil: index) : .buffer
            } else {
                return .cut(before: string.startIndex, consumingUntil: index)
            }
        case LF:
            return .cut(before: string.startIndex, consumingUntil: bytes.index(after: bytes.startIndex))
        case nil, _:
            return nil
        }
    }
}

// MARK: - SeparatorParserStrategy

internal struct SeparatorParserStrategy: ReadingStrategyProtocol {

    public private(set) var options: ReadingStrategyOptions
    private let separator: String
    private let escapeAlgorithm: EscapeAlgorithm?
    
    public init(separator: String, options: ReadingStrategyOptions, escapeAlgorithm: EscapeAlgorithm? = nil) {
        self.options = options
        self.separator = separator
        self.escapeAlgorithm = escapeAlgorithm
    }
    
    public mutating func parse(
        _ string: borrowing Substring,
        options: SegmentParsingOptions
    ) -> SegmentationAction? {
        if let action = self.escapeAlgorithm?.parse(string, options: options) {
            return action
        }
        
        guard let (cutIndex, isParital) = string.utf8.indexOfPrefix(self.separator.utf8) else { return nil }
        guard !isParital else { return options.isAtEnd ? nil : .buffer }
        return .cut(before: string.startIndex, consumingUntil: cutIndex)
    }
}
