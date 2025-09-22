import Foundation
import Testing
@testable import XSV

@Suite("Data-driven XSV tests")
struct DataDrivenXSVTests {
    enum TestError: Error {
        case missingManifest
        case missingCaseFile(String)
        
        var description: String {
            switch self {
            case .missingManifest:
                "Missing test data manifest"
            case .missingCaseFile(let name):
                "Missing base file for case \(name)"
            }
        }
    }
    
    typealias Manifest = [String]
    
    struct TestCase: Sendable, Hashable, CustomStringConvertible {
        let baseName: String
        let jsonURL: URL
        let csvURL: URL?

        var description: String {
            // This is what shows up in the test list per argument.
            // Example: "Orders (csv+json)" or "Users (json)"
            if csvURL != nil {
                return "\(baseName) (csv+json)"
            } else {
                return "\(baseName) (json)"
            }
        }
    }
    
    static let bundle: Bundle = .module
    
    static func loadManifest() throws -> Manifest {
        guard
            let url = self.bundle.url(forResource: "MANIFEST", withExtension: "json")
        else { throw TestError.missingManifest }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Manifest.self, from: data)
    }

    static func discoverCases() throws -> [TestCase] {
        let manifest = try loadManifest()

        return try manifest.compactMap { base in
            guard
                let json = self.bundle.url(forResource: base, withExtension: "json")
            else { throw TestError.missingCaseFile(base) }
            let csv = self.bundle.url(forResource: base, withExtension: "csv")
            return .init(baseName: base, jsonURL: json, csvURL: csv)
        }
    }

    static var cases: [TestCase] {
        do {
            return try discoverCases()
        } catch {
            fatalError("\(error)")
        }
    }

    @Test("DataTest", arguments: cases)
    func run(case dataCase: TestCase) throws {
        let jsonData = try Data(contentsOf: dataCase.jsonURL)

        if let csvURL = dataCase.csvURL {
            let csvData = try Data(contentsOf: csvURL)
            try runCSVTest(jsonData: jsonData, csvData: csvData, baseName: dataCase.baseName)
        }
    }

    // MARK: - Your test logic

    private func runCSVTest(jsonData: Data, csvData: Data, baseName: String) throws {
        let expected = try JSONDecoder().decode([[String]].self, from: jsonData)
        let actual = CSV(parsing: csvData, encoding: .utf8)
        
        try #require(actual != nil, "Failed to parse CSV data")
        let actualSimple: [[String]] = actual!.map { $0.map { $0 } }
        
        #expect(areEqualGroups(expected, actualSimple), "diff: \(diffGroup(expected, actualSimple))")
    }
}
