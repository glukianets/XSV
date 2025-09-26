import Swift

public typealias CSV = Segment<CSVFileStrategy>
public typealias CSVRow = Segment<CSVRowStrategy>

// MARK: - CSVRowStrategy

public struct CSVRowStrategy: SegmentStrategy {
    public typealias Value = String
    private static let escapeAlgorithm: EscapeAlgorithm = .rfc4180
    
    public static func readingStrategy() -> some ReadingStrategyProtocol {
        SeparatorParserStrategy(
            separator: "\u{2C}",
            options: [.skipsEmptyAtEnd],
            escapeAlgorithm: self.escapeAlgorithm
        )
    }

    public static func writingStrategy() -> some WritingStrategyProtocol {
        return SeparatorWritingStrategy(separator: ",")
    }
    
    public static func rehydrate(_ memento: Memento<Value>) -> Value {
        Value(Self.escapeAlgorithm.unescape(memento.value))
    }
    
    public static func dehydrate(_ value: Value, into stream: inout some TextOutputStream) {
        Self.escapeAlgorithm.escape(value[...]).write(to: &stream)
    }
}

// MARK: - CSVFileStrategy

public struct CSVFileStrategy: SegmentStrategy {
    public typealias Value = CSVRow
        
    public static func rehydrate(_ memento: Memento<Value>) -> Value {
        Value(memento: memento)
    }
    
    public static func dehydrate(_ value: Value, into stream: inout some TextOutputStream) {
        value.write(to: &stream)
    }
    
    public static func readingStrategy() -> some ReadingStrategyProtocol {
        LineReadingStrategy()
    }

    public static func writingStrategy() -> some WritingStrategyProtocol {
        LineWritingStrategy(separator: [.cr, .lf])
    }
}

extension String { //RFC-4180
    fileprivate func csvEscaped() -> String {
        if self.contains(",") || self.contains("\"") || self.contains("\n") {
            "\"\(self.replacingOccurrences(of: "\"", with: "\"\""))\""
        } else {
            self
        }
    }
    
    fileprivate func csvUnescaped() -> String {
        guard self.hasPrefix("\"") && self.hasSuffix("\"") && self.count >= 2 else { return self }
        return self.dropFirst().dropLast().replacingOccurrences(of: "\"\"", with: "\"")
    }
}
