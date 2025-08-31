import Foundation
import Testing
@testable import XSV

@Suite("XSV Randomized tests")
struct XSVRandomizedTests {
    @Test("Randomized round-trip match against mock model", arguments: 0..<128)
    func randomizedRoundTripAgainstMock(iteration: Int) throws {
        var rng = LCG(iteration: iteration)
        
        try self.randomizedRoundTrip(rng: &rng, type: [[[[String]]]].self)
    }

    @Test("Randomized round-trip match against self", arguments: 0..<128)
    func randomizedRoundTripAgainstSelf(iteration: Int) throws {
        var rng = LCG(iteration: iteration)
        
        try self.randomizedRoundTrip(rng: &rng, type: XSV.self)
    }
    
    private func randomizedRoundTrip<T>(rng: inout LCG, type: T.Type = T.self) throws where T == PackageLike<T> {
        let model: T = generatePackage(rng: &rng)
        let raw: Data = serializePackage(model)

        let parsed = XSV(String(decoding: raw, as: UTF8.self))
        #expect(parsed == model, "Parsed value mismatch")

        let reserialized = parsed.value.data(using: .utf8)!
        #expect(reserialized == raw, "Round-trip mismatch")
    }
    
    static let x: Int = 0
}
