import Foundation

internal typealias SegmentationEvent = (level: Int, range: Range<String.Index>)

internal struct Segmentator: IteratorProtocol {
    public typealias Index = String.Index
    public typealias Element = SegmentationEvent

    private var string: Substring.UTF8View
    private var strategies: [any SegmentationStrategy]
    private var rangeStarts: [Index]
    private var outputBuffer: [Element]
    private var index: Index

    public init(_ string: borrowing Substring, strategies: some Sequence<any SegmentationStrategy>) {
        self.string = string.utf8
        self.strategies = Array(strategies)
        self.index = self.string.startIndex
        self.rangeStarts = .init(repeating: self.index, count: self.strategies.count)
        self.outputBuffer = []
        self.outputBuffer.reserveCapacity(self.strategies.count)
    }
        
    public mutating func next() -> Element? {
    el: repeat {
            if let element = self.outputBuffer.popLast(){ return element }

            while self.index < self.string.endIndex {
                let byte = self.string[self.index]

                defer { self.string.formIndex(after: &self.index) }

                for i in self.strategies.indices {
                    let action = self.strategies[i].step(byte: byte)
                    
                    if case .cut = action {
                        self.close(at: i + 1)
                        continue el
                    }
                }
            }

            self.close(at: self.strategies.count)
            self.strategies = []
        } while self.index < self.string.endIndex || !self.outputBuffer.isEmpty
        
        return nil
    }
    
    @inline(__always)
    private mutating func close(at level: Int) {
        let nextIndex = min(self.string.endIndex, self.string.index(after: self.index))
        for i in (0..<level).reversed() {
            self.outputBuffer.append(SegmentationEvent(level: i, range: rangeStarts[i]..<self.index))
            rangeStarts[i] = nextIndex
            self.strategies[i].resetForNewSegment()
        }
    }
}

