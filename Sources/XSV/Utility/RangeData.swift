import Foundation

internal struct RangeData: Hashable {
    internal struct Element: Hashable{
        var range: Range<String.Index>
        var value: RangeData
    }

    internal var ranges: [Element]
   
    internal var isEmpty: Bool {
        self.ranges.isEmpty || self.ranges.first!.range.isEmpty
    }
    
    internal init() {
        self.ranges = []
    }
    
    internal init(in data: Substring, separators: ClosedRange<ASCIISeparator>) {
        self = Self.splitRanges(in: data, separators: separators)
    }
    
    fileprivate init(ranges: [Element]) {
        self.ranges = ranges
    }

//    internal static func splitRanges(in string: Substring, separators: ClosedRange<ASCIISeparator>) -> RangeData {
//        typealias Seg = Segmentator<XSVPackageStrategy, Segmentator<XSVFileStrategy, Segmentator<XSVGroupStrategy, Segmentator<XSVRecordStrategy, Segmentator<XSVUnitStrategy, StringFeeder>>>>>
//        
//        let segmentator: Seg = .init(.init(.init(.init(.init(.ready(string))))))
//        return splitRanges(segmentator)
//    }
    
    internal static func splitRanges(in string: Substring, separators: ClosedRange<ASCIISeparator>) -> RangeData {
        let segmentator: Segmentator = .init(string, strategies: [
            XSVUnitStrategy.self,
            XSVRecordStrategy.self,
            XSVGroupStrategy.self,
            XSVFileStrategy.self,
            XSVPackageStrategy.self,
        ])
        
        return splitRanges(segmentator)
    }

    internal static func splitRanges<S: IteratorProtocol>(_ segmentator: S) -> RangeData where S.Element == (level: Int, range: Range<String.Index>) {
        var segmentator = segmentator

        var levels: [RangeData] = []

        while let (level, range) = segmentator.next() {
            if levels.count <= level {
                levels.append(contentsOf: repeatElement(.init(), count: level + 1 - levels.count))
            }
            let child = level == 0 ? .init() : levels[level - 1]
            levels[level].ranges.append(Element(range: range, value: child))
            levels[0..<level] = .init(repeating: .init(), count: level)
        }

        return levels.last { !$0.isEmpty } ?? .init()
    }
}

