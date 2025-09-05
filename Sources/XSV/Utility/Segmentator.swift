import Foundation

fileprivate let fs: Int = 0
fileprivate let gs: Int = 1
fileprivate let rs: Int = 2
fileprivate let us: Int = 3

internal struct Segmentator: IteratorProtocol {
    public typealias Index = String.Index
    public typealias Element = (level: Int, range: Range<Index>)

    private var string: Substring.UTF8View
    private var strategies: [any SegmentationStrategy.Type]
    private var rangeStarts: [Index]
    private var outputBuffer: [Element]
    private var index: Index

    public init(_ string: borrowing Substring, strategies: some Collection<any SegmentationStrategy.Type>) {
        self.string = string.utf8
        self.strategies = Array(strategies)
        self.index = self.string.startIndex
        self.rangeStarts = .init(repeating: self.index, count: strategies.count)
        self.outputBuffer = []
        self.outputBuffer.reserveCapacity(strategies.count)
    }
        
    public mutating func next() -> Element? {
        outer: repeat {
            if let element = self.outputBuffer.popLast(){ return element }

            while self.index < self.string.endIndex {
                let char = self.string[self.index]
                defer { self.string.formIndex(after: &self.index) }
                guard let cut = self.strategies.firstIndex(where: { char == $0.separator }) else { continue }
                self.close(at: cut + 1)
                continue outer
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
            self.outputBuffer.append((level: i, range: rangeStarts[i]..<self.index))
            rangeStarts[i] = nextIndex
        }
    }
}
//
//internal struct XSVSegmentator: IteratorProtocol {
//    public typealias Index = String.Index
//
//    public enum Element {
//        case file(Range<Index>)
//        case group(Range<Index>)
//        case record(Range<Index>)
//        case unit(Range<Index>)
//    }
//
//    private var string: Substring.UTF8View
//    private var rangeStarts: InlineArray<4, Index>
//    private var outputBuffer: InlineArray<4, Element>
//    private var outputBufferCount: Int = 0
//    private var index: Index
//
//    public init(_ string: borrowing Substring) {
//        self.string = string.utf8
//        self.index = self.string.startIndex
//        self.rangeStarts = .init(repeating: self.index)
//        self.outputBuffer = .init(repeating: .file(self.index..<self.index))
//    }
//        
//    public mutating func next() -> Element? {
//        if let e = dequeue() { return e }
//        
//        while self.index <= self.string.endIndex {
//            let char = self.index < self.string.endIndex ? self.string[self.index] : nil
//            defer { self.string.formIndex(after: &self.index) }
//            
//            switch char {
//            case nil:
//                fallthrough
//            case ASCIISeparator.fs.rawValue?:
//                enqueue(.file(rangeStarts[fs]..<index))
//                rangeStarts[fs] = self.string.index(after: index)
//                fallthrough
//            case ASCIISeparator.gs.rawValue?:
//                enqueue(.group(rangeStarts[gs]..<index))
//                rangeStarts[gs] = self.string.index(after: index)
//                fallthrough
//            case ASCIISeparator.rs.rawValue?:
//                enqueue(.record(rangeStarts[rs]..<index))
//                rangeStarts[rs] = self.string.index(after: index)
//                fallthrough
//            case ASCIISeparator.us.rawValue?:
//                enqueue(.unit(rangeStarts[us]..<index))
//                rangeStarts[us] = self.string.index(after: index)
//                return dequeue()
//            default:
//                break
//            }
//        }
//        
//        return nil
//    }
//
//    @inline(__always)
//    private mutating func enqueue(_ e: Element) {
//        self.outputBuffer[self.outputBufferCount] = e
//        self.outputBufferCount &+= 1
//    }
//
//    @inline(__always)
//    private mutating func dequeue() -> Element? {
//        guard self.outputBufferCount > 0 else { return nil }
//        self.outputBufferCount &-= 1
//        return self.outputBuffer[self.outputBufferCount]
//    }
//}
//
//internal protocol SegmentatorProtocol: IteratorProtocol {
//    mutating func cut(at index: SegmentationEvent.Index)
//    mutating func drain() -> SegmentationEvent?
//    mutating func next() -> SegmentationEvent?
//}
//
//public enum SegmentationEvent {
//    public typealias Index = String.Index
//    
//    case completeSegment(level: Int, range: Range<Index>)
//    case contents(Substring)
//}
//
//internal enum StringFeeder: SegmentatorProtocol {
//    typealias Index = String.Index
//    
//    case ready(Substring)
//    case completed(Range<Index>)
//    case finished
//    
//    public mutating func cut(at index: SegmentationEvent.Index) {
//        // nothing
//    }
//    
//    public mutating func drain() -> SegmentationEvent? {
//        // nothing
//        return nil
//    }
//    
//    public mutating func next() -> SegmentationEvent? {
//        switch self {
//        case .ready(let value):
//            defer { self = .completed(value.startIndex..<value.endIndex) }
//            return .contents(value)
//        case .completed(let range):
//            defer { self = .finished }
//            return .completeSegment(level: 0, range: range)
//        case .finished:
//            return nil
//        }
//    }
//}
//
//
//internal struct Segmentator<Strategy: SegmentationStrategy, Wrapped: SegmentatorProtocol>: SegmentatorProtocol {
//    public typealias Index = String.Index
//
//    private var buffer: SegmentationEvent?
//    private var overflow: Substring?
//    private var wrapped: Wrapped
//    private var currentRange: Range<Index>!
//
//    public init(_ wrapped: Wrapped) {
//        self.wrapped = wrapped
//    }
//    
//    public mutating func cut(at index: Index) {
//        self.wrapped.cut(at: index)
//        assert(self.buffer == nil, "Segmentator can not cut while draining previous cut")
//        self.buffer = .completeSegment(level: 0, range: self.currentRange.lowerBound..<index)
//
//        guard let overflow else { preconditionFailure() }
//        let index = overflow.index(after: index)
//        self.overflow = overflow[index...]
//        self.currentRange = index..<max(index, self.currentRange.upperBound)
//    }
//
//    public mutating func drain() -> SegmentationEvent? {
//        switch self.wrapped.drain() {
//        case nil:
//            if let buffer {
//                self.buffer = nil
//                return buffer
//            } else if let currentRange {
//                self.currentRange = self.currentRange.upperBound..<self.currentRange.upperBound
//                return currentRange.isEmpty ? nil : .completeSegment(level: 0, range: currentRange)
//            } else {
//                return nil
//            }
//        case .contents(let s)?:
//            assertionFailure("Inner segmentator must never drain contents")
//            return .contents(s)
//        case .completeSegment(level: let l, range: let r)?:
//            return .completeSegment(level: l + 1, range: r)
//        }
//    }
//    
//    public mutating func next() -> SegmentationEvent? {
//        if self.buffer != nil, let inner = self.drain() {
//            return inner
//        }
//        
//        if let overflow, !overflow.isEmpty {
//            if let sep = overflow.utf8.firstIndex(of: Strategy.separator) {
//                defer { self.cut(at: sep) }
//                return .contents(overflow[..<sep])
//            } else {
//                self.currentRange = self.currentRange.lowerBound..<overflow.endIndex
//                self.overflow = nil
//                // fallthrough
//            }
//        }
//        
//        switch self.wrapped.next() {
//        case nil:
//            return self.drain()
//        case .contents(let chunk):
//            assert(self.overflow?.isEmpty ?? true)
//            self.overflow = chunk
//            self.currentRange ??= chunk.startIndex..<chunk.endIndex
//            return self.next()
//        case .completeSegment(level: let level, range: let range):
//            self.currentRange ??= range
//            self.currentRange = self.currentRange!.lowerBound..<max(range.upperBound, self.currentRange!.upperBound)
//            return .completeSegment(level: level + 1, range: range)
//        }
//    }
//}
