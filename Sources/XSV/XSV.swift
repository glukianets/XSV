import Swift

public protocol _SegmentProtocol: Hashable & LosslessStringConvertible {
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

public typealias XSV = Segment<0x1C, XSVFile>
public typealias XSVFile = Segment<0x1D, XSVGroup>
public typealias XSVGroup = Segment<0x1E, XSVRecord>
public typealias XSVRecord = Segment<0x1F, Unit>
