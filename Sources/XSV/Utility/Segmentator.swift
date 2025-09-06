import Foundation

internal typealias SegmentationEvent = (level: Int, range: Range<String.Index>)

internal struct Segmentator: IteratorProtocol {
    public typealias Index = String.Index
    public typealias Element = SegmentationEvent

    private var string: Substring
    private var strategies: [any SegmentationStrategy]
    private var rangeStarts: [Index]
    private var outputBuffer: [Element]
    private var index: Index

    public init(_ string: borrowing Substring, strategies: some Sequence<any SegmentationStrategy>) {
        self.string = string[...]
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
                let nextIndex = self.string.index(after: self.index)
                
                defer { self.index = nextIndex }

                for i in self.strategies.indices {
                    let action = self.strategies[i].step(self.string[self.index..<nextIndex])
                    
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
        let nextIndex = self.string.index(self.index, offsetBy: 1, limitedBy: self.string.endIndex) ?? self.string.endIndex
          //min(self.string.endIndex, self.string.index(after: self.index))
        for i in (0..<level).reversed() {
            self.outputBuffer.append(SegmentationEvent(level: i, range: rangeStarts[i]..<self.index))
            rangeStarts[i] = nextIndex
            self.strategies[i].resetForNewSegment()
        }
    }
}

