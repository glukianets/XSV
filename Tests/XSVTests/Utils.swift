import Foundation
import Testing
@testable import XSV
import struct XSV.Unit

typealias PackageLike<C> = C where C: RangeReplaceableCollection, C.Element == FileLike<C.Element>
typealias FileLike<C> = C where C: RangeReplaceableCollection, C.Element == GroupLike<C.Element>
typealias GroupLike<C> = C where C: RangeReplaceableCollection, C.Element == RecordLike<C.Element>
typealias RecordLike<C> = C where C: RangeReplaceableCollection, C.Element: LosslessStringConvertible

// MARK: - Generation

// ASCII separators
let FS: UInt8 = 0x1C // 28
let GS: UInt8 = 0x1D // 29
let RS: UInt8 = 0x1E // 30
let US: UInt8 = 0x1F // 31

internal struct LCG: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64) { self.state = seed != 0 ? seed : 0xdead_beef_feed_cafe }
    
    public init(iteration: Int) {
        self.init(seed: 0xABCD_1234_5678_0000 &+ UInt64(iteration))
    }

    mutating func next() -> UInt64 {
        state &*= 6364136223846793005
        state &+= 1
        return state
    }

    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        let span = UInt64(range.upperBound - range.lowerBound + 1)
        let rnd = next() % span
        return range.lowerBound + Int(rnd)
    }
}

struct GenerationConfig {
    let filesRange  = 1...10
    let groupsRange = 1...10
    let recordsRange = 1...10
    let unitsRange   = 1...10
    let unitSizeRange = 1...100
}

func generatePackage<C>(rng: inout LCG, config: GenerationConfig = .init()) -> C where C == PackageLike<C>
{
    var model: C = .init()

    let fCount = rng.nextInt(in: config.filesRange)
    for _ in 0..<fCount {
        model.append(generateFile(rng: &rng, config: config))
    }
    
    return model
}

func generateFile<C>(rng: inout LCG, config: GenerationConfig = .init()) -> C where C == FileLike<C> {
    var groups: C = .init()
    let gCount = rng.nextInt(in: config.groupsRange)

    for _ in 0..<gCount {
        groups.append(generateGroup(rng: &rng, config: config))
    }
    
    return groups
}

func generateGroup<C>(rng: inout LCG, config: GenerationConfig = .init()) -> C where C == GroupLike<C> {
    var records: C = .init()
    let rCount = rng.nextInt(in: config.recordsRange)

    for _ in 0..<rCount {
        records.append(generateRecord(rng: &rng, config: config))
    }

    return records
}

func generateRecord<C>(rng: inout LCG, config: GenerationConfig = .init()) -> C where C == RecordLike<C> {
    var units: C = .init()
    let uCount = rng.nextInt(in: config.unitsRange)
    
    for _ in 0..<uCount {
        units.append(generateUnit(rng: &rng, config: config))
    }
    
    return units
}

func generateUnit<T: LosslessStringConvertible>(rng: inout LCG, config: GenerationConfig) -> T {
    let length = rng.nextInt(in: config.unitSizeRange)
    var scalars = String.UnicodeScalarView()
    for _ in 0..<length {
        var scalar: UnicodeScalar
        repeat {
            let value = UInt32(rng.nextInt(in: 0x20...0xD7FF)) // skip C0 and surrogates
            scalar = UnicodeScalar(value) ?? UnicodeScalar(0x20)
        } while CharacterSet.controlCharacters.contains(scalar)
        scalars.append(scalar)
    }
    
    guard let result = T(String(scalars)) else { fatalError("Generated type T must be constructible from arbitrary string") }
    return result
}

// MARK: - Serialization

func serializePackage<C>(_ files: C) -> Data where C == PackageLike<C> {
    var out = Data()
    for file in files {
        out.append(serializeFile(file))
        out.append(FS)
    }
    if !files.isEmpty { out.removeLast() }
    return out
}

func serializeFile<C>(_ groups: C) -> Data where C == FileLike<C> {
    var out = Data()
    for group in groups {
        out.append(serializeGroup(group))
        out.append(GS)
    }
    if !groups.isEmpty { out.removeLast() }
    return out
}

func serializeGroup<C>(_ records: C) -> Data where C == GroupLike<C> {
    var out = Data()
    for record in records {
        out.append(serializeUnit(record))
        out.append(RS)
    }
    if !records.isEmpty { out.removeLast() }
    return out
}

func serializeUnit<C>(_ units: C) -> Data where C == RecordLike<C> {
    var out = Data()
    for unit in units {
        out.append(Data(unit.description.utf8))
        out.append(US)
    }
    if !units.isEmpty { out.removeLast() }
    return out
}

// MARK: - Comparison

func == <L, R>(_ lhs: PackageLike<L>, _ rhs: PackageLike<R>) -> Bool {
    guard lhs.count == rhs.count else { return false }
    for (f1, f2) in zip(lhs, rhs) {
        if !(==)(f1, f2) { return false }
    }
    return true
}

func == <L, R>(_ lhs: FileLike<L>, _ rhs: FileLike<R>) -> Bool {
    guard lhs.count == rhs.count else { return false }
    for (g1, g2) in zip(lhs, rhs) {
        if !(==)(g1, g2) { return false }
    }
    return true
}

func == <L, R>(_ lhs: GroupLike<L>, _ rhs: GroupLike<R>) -> Bool {
    guard lhs.count == rhs.count else { return false }
    for (r1, r2) in zip(lhs, rhs) {
        if !(==)(r1, r2) { return false }
    }
    return true
}

func == <L, R>(_ lhs: RecordLike<L>, _ rhs: RecordLike<R>) -> Bool {
    guard lhs.count == rhs.count else { return false }
    for (u1, u2) in zip(lhs, rhs) {
        if u1.description != u2.description { return false }
    }
    return true
}

func == (_ lhs: some StringProtocol, _ rhs: Unit) -> Bool {
    return lhs == rhs.value
}

func == (_ lhs: Unit, _ rhs: some StringProtocol) -> Bool {
    return lhs.value == rhs
}
