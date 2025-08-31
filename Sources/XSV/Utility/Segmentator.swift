import Foundation

fileprivate let fs: Int = 0
fileprivate let gs: Int = 1
fileprivate let rs: Int = 2
fileprivate let us: Int = 3

internal struct Segmentator: IteratorProtocol {
    public typealias Index = String.Index

    public enum Element {
        case file(Range<Index>)
        case group(Range<Index>)
        case record(Range<Index>)
        case unit(Range<Index>)
    }

    private var string: Substring.UTF8View
    private var rangeStarts: InlineArray<4, Index>
    private var outputBuffer: InlineArray<4, Element>
    private var outputBufferCount: Int = 0
    private var index: Index

    public init(_ string: borrowing Substring) {
        self.string = string.utf8
        self.index = self.string.startIndex
        self.rangeStarts = .init(repeating: self.index)
        self.outputBuffer = .init(repeating: .file(self.index..<self.index))
    }
        
    public mutating func next() -> Element? {
        if let e = dequeue() { return e }
        
        while self.index <= self.string.endIndex {
            let char = self.index < self.string.endIndex ? self.string[self.index] : nil
            defer { self.string.formIndex(after: &self.index) }
            
            switch char {
            case nil:
                fallthrough
            case ASCIISeparator.fs.rawValue?:
                enqueue(.file(rangeStarts[fs]..<index))
                rangeStarts[fs] = self.string.index(after: index)
                fallthrough
            case ASCIISeparator.gs.rawValue?:
                enqueue(.group(rangeStarts[gs]..<index))
                rangeStarts[gs] = self.string.index(after: index)
                fallthrough
            case ASCIISeparator.rs.rawValue?:
                enqueue(.record(rangeStarts[rs]..<index))
                rangeStarts[rs] = self.string.index(after: index)
                fallthrough
            case ASCIISeparator.us.rawValue?:
                enqueue(.unit(rangeStarts[us]..<index))
                rangeStarts[us] = self.string.index(after: index)
                return dequeue()
            default:
                break
            }
        }
        
        return nil
    }

    @inline(__always)
    private mutating func enqueue(_ e: Element) {
        self.outputBuffer[self.outputBufferCount] = e
        self.outputBufferCount &+= 1
    }

    @inline(__always)
    private mutating func dequeue() -> Element? {
        guard self.outputBufferCount > 0 else { return nil }
        self.outputBufferCount &-= 1
        return self.outputBuffer[self.outputBufferCount]
    }
}
