import Swift

internal struct RangeData: Hashable {
    internal struct Element: Hashable{
        var segment: Substring
        var value: RangeData
    }
    
    internal var ranges: [Element]
    
    internal var isEmpty: Bool {
        self.ranges.isEmpty || self.ranges.first!.segment.isEmpty
    }
    
    internal init() {
        self.ranges = []
    }
    
    internal init<S>(segmentator: S) where S: IteratorProtocol, S.Element == SegmentationEvent {
        var segmentator = segmentator
        
        var levels: [RangeData] = []
        
        while case let (level, segment)? = segmentator.next() {
            if levels.count <= level {
                levels.append(contentsOf: repeatElement(.init(), count: level + 1 - levels.count))
            }
            let child = level == 0 ? .init() : levels[level - 1]
            levels[level].ranges.append(Element(segment: segment, value: child))
            levels[0..<level] = .init(repeating: .init(), count: level)
        }
        
        self = levels.last { !$0.isEmpty } ?? .init()
    }
    
    fileprivate init(ranges: [Element]) {
        self.ranges = ranges
    }
}

