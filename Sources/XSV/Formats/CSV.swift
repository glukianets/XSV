import Swift

public typealias CSV = Segment<CSVFileStrategy>
public typealias CSVRow = Segment<CSVRowStrategy>

private struct Constants {
    static let comma: UInt8 = 0x2C
    static let doublequote: UInt8 = 0x22
}

// MARK: - CSVRowStrategy

public struct CSVRowStrategy: SegmentStrategy {
    public typealias Value = String
    
    public struct WritingStrategy: WritingStrategyProtocol { }
    
    public static func readingStrategy() -> some ReadingStrategyProtocol {
        SeparatorParserStrategy(separator: "\u{2C}", options: [.skipsEmptyAtEnd], escapeAlgorithm: .rfc4180)
    }

    public static func writingStrategy() -> WritingStrategy {
        .init()
    }
    
    public static func rehydrate(_ memento: Memento<Value>) -> Value {
        Value(memento.value).csvUnescaped()
    }
    
    public static func dehydrate(_ value: Value, into stream: inout some TextOutputStream) {
        value.csvEscaped().write(to: &stream)
    }
}

// MARK: - CSVFileStrategy

public struct CSVFileStrategy: SegmentStrategy {
    public typealias Value = CSVRow
    
    public struct WritingStrategy: WritingStrategyProtocol {
        //
    }
    
    public static func rehydrate(_ memento: Memento<Value>) -> Value {
        Value(memento: memento)
    }
    
    public static func dehydrate(_ value: Value, into stream: inout some TextOutputStream) {
        value.write(to: &stream)
    }
    
    public static func readingStrategy() -> some ReadingStrategyProtocol {
        LineReadingStrategy()
    }

    public static func writingStrategy() -> WritingStrategy {
        .init()
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
