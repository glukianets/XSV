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

public struct SeparatorParserStrategy: ReadingStrategyProtocol {
    public enum EscapeAlgorithm {
        case quotation(symbol: UnicodeScalar)
        
        public static var rfc4180: Self { self.quotation(symbol: "\"") }
    }
    
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
        switch self.escapeAlgorithm {
        case .quotation(let symbol)?:
            let string = string.unicodeScalars
            guard string.first == symbol else { break }
            var index = string.index(after: string.startIndex)
            
            while index < string.endIndex {
                if string[index] == symbol {
                    let nextIndex = string.index(after: index)
                    guard nextIndex < string.endIndex || options.isAtEnd else { return .buffer }
                    guard string[nextIndex] == symbol else { return .consume(through: index) }
                    index = nextIndex
                }
                string.formIndex(after: &index)
            }
            
            return options.isAtEnd ? nil : .buffer

        case nil:
            break
        }
        
        guard let (cutIndex, isParital) = string.utf8.indexOfPrefix(self.separator.utf8) else { return nil }
        guard !isParital else { return options.isAtEnd ? nil : .buffer }
        return .cut(before: string.startIndex, consumingUntil: cutIndex)
    }
}
