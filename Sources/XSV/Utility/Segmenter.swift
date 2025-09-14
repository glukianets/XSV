import Swift

internal typealias SegmentationEvent = (level: Int, range: Range<String.Index>)

internal struct Segmenter: IteratorProtocol {
    public typealias Index = String.Index
    public typealias Element = SegmentationEvent

    private var string: Substring
    private var strategies: [any UnitStrategy]
    private var rangeStarts: [Index]
    private var outputBuffer: [Element]
    private var index: Index

    public init(_ string: borrowing Substring, strategies: some Sequence<any UnitStrategy>) {
        self.string = string[...]
        self.strategies = Array(strategies)
        self.index = self.string.startIndex
        self.rangeStarts = .init(repeating: self.index, count: self.strategies.count)
        self.outputBuffer = []
        self.outputBuffer.reserveCapacity(self.strategies.count)
    }
        
    public mutating func next() -> Element? {
    el: repeat {
            if let element = self.outputBuffer.popLast() { return element }

        ch: while self.index < self.string.endIndex {
                defer { self.string.formIndex(after: &self.index) }

                for i in self.strategies.indices {
                    guard let action = self.strategies[i].step(self.string[self.index...]) else { continue }
                    
                    switch action {
                    case .cut(before: let nextIndex):
                        assert(self.index...self.string.endIndex ~= nextIndex)
                        self.close(at: i + 1, continueAt: nextIndex)
                        self.index = string.index(before: nextIndex)
                        continue el
                    case .consume(through: let nextIndex):
                        self.index = nextIndex
                        continue ch
                    case .buffer:
                        continue
                    }
                }
            }

            self.close(at: self.strategies.count, continueAt: self.string.endIndex)
            self.strategies = []
        } while self.index < self.string.endIndex || !self.outputBuffer.isEmpty
        
        return nil
    }
    
    @inline(__always)
    private mutating func close(at level: Int, continueAt nextIndex: Index) {
        for i in (0..<level).reversed() {
            self.outputBuffer.append(SegmentationEvent(level: i, range: rangeStarts[i]..<self.index))
            rangeStarts[i] = nextIndex
            self.strategies[i].resetForNewSegment()
        }
    }
}

