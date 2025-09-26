import Swift

internal enum EscapeAlgorithm: Sendable & Hashable {
    case surround(symbol: String)
    case prefix(symbol: String, whitelist: [String])
    
    public static var rfc4180: Self { self.surround(symbol: "\"") }
    
    public func parse(
        _ string: borrowing Substring,
        options: SegmentParsingOptions
    ) -> SegmentationAction?? {
        switch self {
        case .surround(let symbol):
            precondition(!symbol.isEmpty)
            guard var (index, isPartial) = string.indexOfPrefix(symbol) else { break }
            guard !isPartial else { return options.isAtEnd ? .some(nil) : .buffer }
            
            while index < string.endIndex {
                guard let next = string[index...].indexOfPrefix(symbol) else {
                    string.formIndex(after: &index)
                    continue
                }
                (index, isPartial) = next
                guard !isPartial else { return options.isAtEnd ? .some(nil) : .buffer }
                
                guard let next = string[index...].indexOfPrefix(symbol) else {
                    return .consume(through: string.index(before: index))
                }
                (index, isPartial) = next
                guard !isPartial else { return options.isAtEnd ? .some(nil) : .buffer }
            }
            
            return options.isAtEnd ? .some(nil) : .buffer
            
        case .prefix(let symbol, let whitelist):
            precondition(!symbol.isEmpty)
            guard var (index, isPartial) = string.indexOfPrefix(symbol) else { break }
            guard !isPartial else { return options.isAtEnd ? .some(nil) : .buffer }
            
            guard index < string.endIndex else { return .buffer }
            
            guard !whitelist.isEmpty else { return .consume(through: string.index(after: index)) }
            
            for escape in whitelist {
                guard let next = string[index...].indexOfPrefix(escape) else { continue }
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
            // Double any occurrences of the symbol within, then wrap with the symbol
            let doubled = symbol + symbol
            let inner = String(string).replacingOccurrences(of: symbol, with: doubled)
            let wrapped = symbol + inner + symbol
            return wrapped[...]

        case .prefix(let symbol, let whitelist):
            guard !symbol.isEmpty else { return string }

            if whitelist.isEmpty {
                // Escape every character by prefixing the escape symbol
                var result = String()
                result.reserveCapacity(string.count * (symbol.count + 1))
                for ch in string {
                    result += symbol
                    result.append(ch)
                }
                return result[...]
            } else {
                // Build a list of (content, fullEscaped) where fullEscaped starts with the escape symbol
                var pairs: [(content: String, full: String)] = []
                pairs.reserveCapacity(whitelist.count)
                for full in whitelist {
                    if full.hasPrefix(symbol) {
                        let content = String(full.dropFirst(symbol.count))
                        if !content.isEmpty {
                            pairs.append((content, full))
                        }
                    }
                }
                // Prefer the longest content first to handle overlaps (e.g., CRLF vs CR)
                pairs.sort { $0.content.count > $1.content.count }

                var result = String()
                result.reserveCapacity(string.count)
                var i = string.startIndex
                while i < string.endIndex {
                    var matched: (content: String, full: String)? = nil
                    for p in pairs {
                        if string[i...].hasPrefix(p.content) {
                            matched = p
                            break
                        }
                    }

                    if let m = matched {
                        result += m.full
                        i = string.index(i, offsetBy: m.content.count)
                    } else {
                        result.append(string[i])
                        i = string.index(after: i)
                    }
                }
                return result[...]
            }
        }
    }
    
    func unescape(_ string: consuming Substring) -> Substring {
        switch self {
        case .surround(let symbol):
            guard !symbol.isEmpty else { return string }
            // Only unescape doubled symbols if the value is actually surrounded
            guard string.hasPrefix(symbol), string.hasSuffix(symbol) else { return string }
            let start = string.index(string.startIndex, offsetBy: symbol.count)
            let end = string.index(string.endIndex, offsetBy: -symbol.count)
            let inner = String(string[start..<end])
            let doubled = symbol + symbol
            let unescaped = inner.replacingOccurrences(of: doubled, with: symbol)
            return unescaped[...]

        case .prefix(let symbol, let whitelist):
            guard !symbol.isEmpty else { return string }
            var result = String()
            result.reserveCapacity(string.count)

            var i = string.startIndex

            if whitelist.isEmpty {
                // Remove the escape symbol and keep the next character (if present)
                while i < string.endIndex {
                    if string[i...].hasPrefix(symbol) {
                        if let afterSymbol = string.index(i, offsetBy: symbol.count, limitedBy: string.endIndex), afterSymbol < string.endIndex {
                            result.append(string[afterSymbol])
                            i = string.index(after: afterSymbol)
                        } else {
                            // Trailing escape symbol with nothing to escape – drop it
                            i = string.endIndex
                        }
                    } else {
                        result.append(string[i])
                        i = string.index(after: i)
                    }
                }
                return result[...]
            } else {
                // Prefer longest match first to properly handle overlapping sequences (e.g., \r\n vs \r)
                let sorted = whitelist.sorted { $0.count > $1.count }
                while i < string.endIndex {
                    var matched: String? = nil
                    for candidate in sorted {
                        if string[i...].hasPrefix(candidate) {
                            matched = candidate
                            break
                        }
                    }

                    if let m = matched {
                        // Append the matched content without the leading escape symbol
                        let matchEnd = string.index(i, offsetBy: m.count, limitedBy: string.endIndex) ?? string.endIndex
                        let contentStart = string.index(i, offsetBy: symbol.count, limitedBy: matchEnd) ?? matchEnd
                        result += string[contentStart..<matchEnd]
                        i = matchEnd
                    } else {
                        // No special escape – copy one character literally
                        result.append(string[i])
                        i = string.index(after: i)
                    }
                }
                return result[...]
            }
        }
    }
}
