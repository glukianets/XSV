import Swift

public typealias CSV = Segment<CSVFileStrategy>
public typealias CSVRow = Segment<CSVRowStrategy>

private struct Constants {
    static let comma: UInt8 = 0x2C
    static let doublequote: UInt8 = 0x22
    static let CR: UInt8 = 0x0D
    static let LF: UInt8 = 0x0A
}

// MARK: - CSVRowStrategy

public struct CSVRowStrategy: SegmentStrategy {
    public typealias Value = String
    
    public struct ReadingStrategy: ReadingStrategyProtocol {
        public mutating func parse(
            _ string: borrowing Substring,
            options: SegmentParsingOptions
        ) -> SegmentationAction? {
            let string = string.utf8
            
            switch string.first {
            case Constants.comma:
                return .cut(before: string.startIndex, consumingUntil: string.index(after: string.startIndex))
            case Constants.doublequote:
                var index = string.index(after: string.startIndex)
                while index < string.endIndex {
                    if string[index] == Constants.doublequote {
                        let nextIndex = string.index(after: index)
                        guard nextIndex < string.endIndex || options.isAtEnd else { return .buffer }
                        guard string[nextIndex] == Constants.doublequote else { return .consume(through: index) }
                        index = nextIndex
                    }
                    string.formIndex(after: &index)
                }
                return .buffer
            case nil, _:
                return nil
            }
        }
    }
    
    public struct WritingStrategy: WritingStrategyProtocol { }
    
    public static func readingStrategy() -> ReadingStrategy {
        .init()
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
    
    public struct ReadingStrategy: ReadingStrategyProtocol {
        public mutating func parse(
            _ string: borrowing Substring,
            options: SegmentParsingOptions
        ) -> SegmentationAction? {
            let bytes = string.utf8
            switch bytes.first {
            case Constants.CR:
                var index = bytes.index(after: bytes.startIndex)
                if index < bytes.endIndex && bytes[index] == Constants.LF {
                    bytes.formIndex(after: &index)
                }
                if index >= bytes.endIndex {
                    // The last newline is skipped since it doesn't denote an element separator
                    return options.isAtEnd ? .consume(through: bytes.startIndex) : .buffer
                } else {
                    return .cut(before: string.startIndex, consumingUntil: index)
                }
            case Constants.LF:
                return .cut(before: string.startIndex, consumingUntil: bytes.index(after: bytes.startIndex))
            case nil, _:
                return nil
            }
        }
    }
    
    public struct WritingStrategy: WritingStrategyProtocol {
        //
    }
    
    public static func rehydrate(_ memento: Memento<Value>) -> Value {
        Value(memento: memento)
    }
    
    public static func dehydrate(_ value: Value, into stream: inout some TextOutputStream) {
        value.write(to: &stream)
    }
    
    public static func readingStrategy() -> ReadingStrategy {
        .init()
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
