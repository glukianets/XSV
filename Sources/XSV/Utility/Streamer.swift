import Swift

// MARK: - StringProvider

internal struct StringProvider: IteratorProtocol {
    private let string: String
    private let segmentSize: Int
    private var currentIndex: String.Index
    
    public init(_ source: some StringProtocol, segmentSize: Int = 10) {
        self.string = String(source)
        self.segmentSize = max(1, segmentSize)
        self.currentIndex = self.string.startIndex
    }
    
    public mutating func next() -> String? {
        guard self.currentIndex < self.string.endIndex else { return nil }
        
        let end = self.string.index(
            self.currentIndex,
            offsetBy: self.segmentSize,
            limitedBy: self.string.endIndex
        ) ?? self.string.endIndex
        let chunk = self.string[self.currentIndex..<end]
        self.currentIndex = end
        return chunk.isEmpty ? nil : String(chunk)
    }
}

// MARK: - WritingStrategyProtocol.withStream

internal struct StreamWrapper<Stream: TextOutputStream, Strategy: WritingStrategyProtocol>: TextOutputStream {
    private let stream: UnsafeMutablePointer<Stream>
    private let strategy: UnsafeMutablePointer<Strategy>
    
    fileprivate init(stream: UnsafeMutablePointer<Stream>, strategy: UnsafeMutablePointer<Strategy>) {
        self.stream = stream
        self.strategy = strategy
    }
    
    public mutating func write(_ string: String) {
        self.strategy.pointee.processElement(string)?.write(to: &self.stream.pointee)
    }
}

extension WritingStrategyProtocol {
    internal mutating func withStream<S: TextOutputStream, RI, RO>(
        _ stream: inout S,
        body: (((inout any TextOutputStream) -> RI) -> RI) -> RO
    ) -> RO {
        self.openSegment()?.write(to: &stream)
        defer { self.closeSegment()?.write(to: &stream) }
        return body { block in
            self.openElement()?.write(to: &stream)
            defer { self.closeElement()?.write(to: &stream) }
            var streamWrapper: any TextOutputStream = StreamWrapper(stream: &stream, strategy: &self)
            return block(&streamWrapper)
        }
    }
}
