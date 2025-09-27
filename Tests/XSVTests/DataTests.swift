import Foundation
import Testing
@testable import XSV

@Suite("Data-driven XSV tests", .serialized)
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
        let tsvURL: URL?

        var description: String {
            let markers: String = [self.csvURL, self.tsvURL].compactMap(\.?.pathExtension).joined(separator: ", ")
            return "\(self.baseName)(\(markers))"
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
            let tsv = self.bundle.url(forResource: base, withExtension: "tsv")
            return .init(baseName: base, jsonURL: json, csvURL: csv, tsvURL: tsv)
        }
    }

    static var cases: [TestCase] {
        do {
            return try discoverCases()
        } catch {
            fatalError("\(error)")
        }
    }

    @Test(arguments: cases)
    func testCSV(case dataCase: TestCase) throws {
        guard let csvURL = dataCase.csvURL else {
            Issue.record("No CSV file provided for \(dataCase.baseName)")
            return
        }

        let jsonData = try Data(contentsOf: dataCase.jsonURL)
        let expected = try JSONDecoder().decode([[String]].self, from: jsonData)
        
        let testData = try Data(contentsOf: csvURL)
        let actual = CSV(parsing: testData, encoding: .utf8)
        
        try #require(actual != nil, "Failed to parse CSV data")
        let actualModel: [[String]] = morphGroup(actual!)
        
        #expect(areEqualGroups(expected, actualModel), "diff: \(diffGroup(expected, actualModel))")
    }

    @Test(arguments: cases)
    func testTSV(case dataCase: TestCase) throws {
        guard let tsvURL = dataCase.tsvURL else {
            Issue.record("No CSV file provided for \(dataCase.baseName)")
            return
        }
        
        let jsonData = try Data(contentsOf: dataCase.jsonURL)
        let expected = try JSONDecoder().decode([[String]].self, from: jsonData)

        let testData = try Data(contentsOf: tsvURL)
        let actual = TSV(parsing: testData, encoding: .utf8)
        
        try #require(actual != nil, "Failed to parse TSV data")
        let actualModel: [[String]] = morphGroup(actual!)
        
        #expect(areEqualGroups(expected, actualModel), "diff: \(diffGroup(expected, actualModel))")
    }
}
