import Swift

public protocol _SegmentProtocol: Hashable & LosslessStringConvertible {
    associatedtype Strategy: SegmentationStrategy
    associatedtype Element: _SegmentProtocol
    
    init(memento: Memento)
    
    var value: Substring { get set }
}

extension _SegmentProtocol {
    public var description: String {
        get { String(self.value) }
        set { self.value = newValue[...] }
    }
}

public struct Memento {
    internal var value: Substring
    internal var ranges: RangeData
    
    internal init(_value: Substring, _ranges: RangeData) {
        self.value = _value
        self.ranges = _ranges
    }
}

public struct XSVPackageStrategy: SegmentationStrategy {
    public static let separator = ASCIISeparator.fs.rawValue
}

public struct XSVFileStrategy: SegmentationStrategy {
    public static let separator = ASCIISeparator.gs.rawValue
}

public struct XSVGroupStrategy: SegmentationStrategy {
    public static let separator = ASCIISeparator.rs.rawValue
}

public struct XSVRecordStrategy: SegmentationStrategy {
    public static let separator = ASCIISeparator.us.rawValue
}

public struct XSVUnitStrategy: SegmentationStrategy {
    public static let separator: UInt8 = 0
}

public typealias XSV = Segment<XSVPackageStrategy, XSVFile>
public typealias XSVFile = Segment<XSVFileStrategy, XSVGroup>
public typealias XSVGroup = Segment<XSVGroupStrategy, XSVRecord>
public typealias XSVRecord = Segment<XSVRecordStrategy, Unit>
