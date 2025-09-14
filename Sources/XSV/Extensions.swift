import Swift

#if canImport(Foundation)

import Foundation

extension UnitProtocol {
    public init?(parsing data: Data, encoding: String.Encoding) {
        guard let string = String(data: data, encoding: encoding) else { return nil }
        self.init(parsing: string)
    }
}

#endif // canImport(Foundation)

extension UnitProtocol {
    public init?(parsing string: some StringProtocol) {
        self.init(rawValue: Substring(string))
    }
}
