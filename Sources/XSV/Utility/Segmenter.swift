import Swift

internal typealias SegmentationEvent = (level: Int, segment: Substring)

internal struct Segmenter<Wrapped>: IteratorProtocol
where Wrapped: IteratorProtocol, Wrapped.Element: StringProtocol {
    public typealias Index = String.Index
    public typealias Element = SegmentationEvent
    private typealias Strategy = (
        strategy: any ReadingStrategyProtocol,
        options: ReadingStrategyOptions,
        state: ReadingStrategyOptions.SkipMask
    )

    private var wrapped: Wrapped?
    private var string: String
    private var strategies: [Strategy]
    private var rangeStarts: [Index]
    private var outputBuffer: [Element]
    private var index: Index
    private var flushTreshold: Int

    public init(wrapping upstream: Wrapped, strategies: some Sequence<any ReadingStrategyProtocol>) {
        self.wrapped = upstream
        self.string = ""
        self.strategies = strategies.map { ($0, $0.options, .atStart) }
        self.index = self.string.startIndex
        self.rangeStarts = .init(repeating: self.index, count: self.strategies.count)
        self.outputBuffer = []
        self.outputBuffer.reserveCapacity(self.strategies.count)
        self.flushTreshold = self.strategies.indices.last { [strategies = self.strategies] in
            !strategies[$0].options.contains(ReadingStrategyOptions.transient)
        }.map { $0 + 1 } ?? self.strategies.count
    }
    
    public mutating func next() -> Element? {
    el: repeat {
            if let element = self.outputBuffer.popLast() { return element }
        
        ch: while !self.string.isEmpty && self.index < self.string.endIndex || self.refill() {
            st: for i in self.strategies.indices {
                    bf: while true {
                        let options = SegmentParsingOptions(isAtEnd: self.wrapped == nil)
                        switch self.strategies[i].strategy.parse(self.string[self.index...], options: options) {
                        case nil:
                            continue st
                        case .cut(before: let index, consumingUntil: let nextIndex):
                            assert(self.index...self.string.endIndex ~= index)
                            assert(index...self.string.endIndex ~= nextIndex)
                            self.close(at: i + 1, index: index, continueAt: nextIndex)
                            continue el
                        case .consume(through: let nextIndex):
                            self.index = self.string.index(after: nextIndex)
                            continue ch
                        case .buffer:
                            assert(!options.isAtEnd)
                            self.refill()
                            continue bf
                        }
                    }
                }
                self.string.formIndex(after: &self.index)
            }
            for i in self.strategies.indices {
                self.strategies[i].state = .atEnd
            }
            self.close(at: self.strategies.count, index: self.string.endIndex, continueAt: self.string.endIndex)
            self.strategies = []
        } while self.index < self.string.endIndex || !self.outputBuffer.isEmpty
        
        return nil
    }
    
    @inline(__always)
    private mutating func close(
        at level: Int,
        index: Index,
        continueAt nextIndex: Index
    ) {
        for i in (0..<level).reversed() {
            if self.rangeStarts[i] != index || !self.strategies[i].options.contains(self.strategies[i].state.options) {
                let segment = if !self.strategies[i].options.contains(.transient) {
                    self.string[self.rangeStarts[i]..<index]
                } else {
                    Substring()
                }
                self.string[self.rangeStarts[i]..<index]
                self.outputBuffer.append(SegmentationEvent(level: i, segment: segment))
            }
            self.rangeStarts[i] = nextIndex
            self.strategies[i].strategy.resetForNewSegment()
            self.strategies[i].state = .inTheMiddle
        }
        if level >= self.flushTreshold {
            self.flush(by: nextIndex)
        } else {
            self.index = nextIndex
        }
    }
    
    @inline(__always)
    private mutating func flush(by index: Index) {
        self.string.removeSubrange(..<index)
        self.index = self.string.startIndex
        for i in self.rangeStarts.indices {
            self.rangeStarts[i] = self.string.startIndex
        }
    }
    
    @inline(__always)
    @discardableResult
    private mutating func refill() -> Bool {
        repeat {
            guard let next = self.wrapped?.next() else { self.wrapped = nil; return false }
            self.string = self.string.appending(next)
        } while self.string.isEmpty
        self.migrateIndices()
        return true
    }
    
    @inline(__always)
    private mutating func migrateIndices() {
        func migrate(_ index: inout Index) {
            let newIndex = index.samePosition(in: self.string)
            precondition(newIndex != nil, "Failed to migrate index \(index) to the new storage")
            index = newIndex!
        }
        
        migrate(&self.index)
        for i in self.rangeStarts.indices {
            migrate(&self.rangeStarts[i])
        }
    }
}
