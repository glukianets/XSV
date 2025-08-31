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

    internal static func splitRanges(in string: Substring, separators: ClosedRange<ASCIISeparator>) -> RangeData {
        typealias Files = RangeData
        typealias Groups = RangeData
        typealias Records = RangeData
        typealias Units = RangeData

        var currentFiles: Files = .init()
        var currentGroups: Groups = .init()
        var currentRecords: Records = .init()
        var currentUnits: Units = .init()
            
        var spliterator = Segmentator(string)

        while let token = spliterator.next() {
            switch token {
            case .file(let range):
                guard separators.contains(.fs) else { continue }
                assert(currentUnits.isEmpty)
                assert(currentRecords.ranges.isEmpty)
                currentFiles.ranges.append(Files.Element(range: range, value: currentGroups))
                currentGroups = .init()
            case .group(let range):
                guard separators.contains(.gs) else { continue }
                assert(currentUnits.isEmpty)
                currentGroups.ranges.append(Groups.Element(range: range, value: currentRecords))
                currentRecords = .init()
            case .record(let range):
                guard separators.contains(.rs) else { continue }
                currentRecords.ranges.append(Records.Element(range: range, value: currentUnits))
                currentUnits = .init()
            case .unit(let range):
                guard separators.contains(.us) else { continue }
                currentUnits.ranges.append(Units.Element(range: range, value: .init()))
            }
        }
        
        assert(currentUnits.ranges.isEmpty)
        assert(currentRecords.ranges.isEmpty)
        assert(currentGroups.ranges.isEmpty)

        return currentFiles
    }
}
