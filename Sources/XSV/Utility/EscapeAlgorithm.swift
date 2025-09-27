import Swift

internal enum EscapeAlgorithm: Sendable & Hashable {
    case surround(symbol: String)
    case prefix(symbol: String, replacements: [String: String])
    
    public static var rfc4180: Self { self.surround(symbol: "\"") }
    
    public func parse(
        _ string: borrowing Substring,
        options: SegmentParsingOptions
    ) -> SegmentationAction?? {
        switch self {
        case .surround(let symbol):
            precondition(!symbol.isEmpty)
            guard var (index, isPartial) = string.indexAfter(prefix: symbol) else { break }
            guard !isPartial else { return options.isAtEnd ? .some(nil) : .buffer }
            
            while index < string.endIndex {
                guard let next = string[index...].indexAfter(prefix: symbol) else {
                    string.formIndex(after: &index)
                    continue
                }
                (index, isPartial) = next
                guard !isPartial else { return options.isAtEnd ? .some(nil) : .buffer }
                
                guard let next = string[index...].indexAfter(prefix: symbol) else {
                    return .consume(through: string.index(before: index))
                }
                (index, isPartial) = next
                guard !isPartial else { return options.isAtEnd ? .some(nil) : .buffer }
            }
            
            return options.isAtEnd ? .some(nil) : .buffer
            
        case .prefix(let symbol, let replacements):
            precondition(!symbol.isEmpty)
            guard var (index, isPartial) = string.indexAfter(prefix: symbol) else { break }
            guard !isPartial else { return options.isAtEnd ? .some(nil) : .buffer }
            
            guard index < string.endIndex else { return .buffer }
            
            guard !replacements.isEmpty else { return .consume(through: string.index(after: index)) }
            
            for (escape,_) in replacements {
                guard let next = string[index...].indexAfter(prefix: escape) else { continue }
                (index, isPartial) = next
                guard !isPartial else { if options.isAtEnd { continue } else { return .buffer } }
                return .consume(through: index)
            }
            
            return .some(nil)
        }
        
        return nil
    }
    
    func escape(_ string: consuming Substring) -> Substring {
        switch self {
        case .surround(let symbol):
            guard !symbol.isEmpty else { return string }
            return "\(symbol)\(string.replacingOccurrences(of: symbol, with: symbol + symbol))\(symbol)"[...]

        case .prefix(let symbol, let replacements):
            guard !symbol.isEmpty else { return string }
            guard !replacements.isEmpty else { return string }
            
            var result = String()
            result.reserveCapacity(string.count)
            var rangeStart = string.startIndex
            var rangeIndex = string.startIndex
            while rangeIndex < string.endIndex {
                for (replacement, escape) in replacements {
                    guard let next = string[rangeIndex...].indexAfter(prefix: escape) else { continue }
                    let (index, isPartial) = next
                    guard !isPartial else { continue }
                    result.append("\(string[rangeStart..<rangeIndex])\(symbol)\(replacement)")
                    rangeStart = index
                    rangeIndex = index
                }
            }
            result.append(String(string[rangeStart...]))
            return result[...]
        }
    }
    
    func unescape(_ string: consuming Substring) -> Substring {
        switch self {
        case .surround(let symbol):
            guard !symbol.isEmpty else { return string }

            guard string.hasPrefix(symbol), string.hasSuffix(symbol) else { return string }
            let start = string.index(string.startIndex, offsetBy: symbol.count)
            let end = string.index(string.endIndex, offsetBy: -symbol.count)
            let inner = String(string[start..<end])
            let doubled = symbol + symbol
            let unescaped = inner.replacingOccurrences(of: doubled, with: symbol)
            return unescaped[...]

        case .prefix(let symbol, let replacements):
            guard !symbol.isEmpty else { return string }
            var result = String()
            result.reserveCapacity(string.count)

            var rangeIndex = string.startIndex
        ou: while rangeIndex < string.endIndex {
                guard
                    let next = string[rangeIndex...].firstRange(of: symbol),
                    !next.partial,
                    next.0.lowerBound < string.endIndex
                else { break }
                
                result.append(String(string[rangeIndex..<next.0.lowerBound]))
                rangeIndex = next.0.upperBound
            
                guard rangeIndex < string.endIndex else { break }

                for (escape, replacement) in replacements {
                    guard let next = string[rangeIndex...].indexAfter(prefix: escape), !next.partial else { continue }
                    result.append(replacement)
                    (rangeIndex, _) = next
                    continue ou
                }

                string.formIndex(after: &rangeIndex) // skip 1
            }
            
            result.append(String(string[rangeIndex...]))
            return result[...]
        }
    }
}
