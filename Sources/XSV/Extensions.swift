import Swift

#if canImport(Foundation)

import Foundation

extension SegmentProtocol {
    public func data(using encoding: String.Encoding, allowLossyConversion: Bool = false) -> Data? {
        self.description.data(using: encoding, allowLossyConversion: allowLossyConversion)
    }
    
    public init?(parsing data: Data, encoding: String.Encoding) {
        guard let string = String(data: data, encoding: encoding) else { return nil }
        self.init(parsing: string)
    }
}

#endif // canImport(Foundation)

extension SegmentProtocol {
    public init(parsing string: some StringProtocol) {
        self.init(memento: Memento<Self>(string))
    }
}
