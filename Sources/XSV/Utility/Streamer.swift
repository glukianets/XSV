import Swift

extension WritingStrategyProtocol {
    public func openSegment() -> String? { nil }
    public func closeSegment() -> String? { nil }

    public func openElement() -> String? { nil }
    public func closeElement() -> String? { nil }

    public func processElement(_ contents: consuming String) -> String? { contents }
}

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
