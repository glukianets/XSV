import Swift

public typealias TSV = Segment<TSVFileStrategy>
public typealias TSVRow = Segment<TSVRowStrategy>

// MARK: - TSVRowStrategy

public struct TSVRowStrategy: SegmentStrategy {
    public typealias Value = String
    
    private static let escapeAlgorithm: EscapeAlgorithm = .prefix(symbol: "\\", whitelist: [])
    
    public static func readingStrategy() -> some ReadingStrategyProtocol {
        SeparatorParserStrategy(
            separator: "\t",
            options: .default,
            escapeAlgorithm: Self.escapeAlgorithm
        )
    }

    public static func writingStrategy() -> some WritingStrategyProtocol {
        SeparatorWritingStrategy(separator: "\t")
    }
    
    public static func rehydrate(_ memento: Memento<Value>) -> Value {
        return String(Self.escapeAlgorithm.unescape(memento.value))
    }
    
    public static func dehydrate(_ value: Value, into stream: inout some TextOutputStream) {
        Self.escapeAlgorithm.escape(value[...]).write(to: &stream)
    }
}

// MARK: - TSVFileStrategy

public struct TSVFileStrategy: SegmentStrategy {
    public typealias Value = TSVRow
    
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
