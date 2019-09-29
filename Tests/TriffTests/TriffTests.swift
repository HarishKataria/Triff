//**************************************************************
//
//  TriffTests
//
//  Created by Harish Kataria
//  Copyright © 2019 Harish Kataria. All rights reserved.
//
//**************************************************************
import XCTest
@testable import Triff

final class TriffTests: XCTestCase {
    func testSuccess() {
        let cellsBefore: [Differentiable] = [
            Language(code:"en"),    // 0
            Language(code:"fr"),    // 1
            Language(code:"ge"),    // 2
            Barcode(code: "1011"),  // 3
        ]
        let cellsAfter: [Differentiable] = [
            Barcode(code: "1011"), // 0
            Language(code:"en"),   // 1
            Language(code:"jp"),   // 2
            Language(code:"kr"),   // 3
            Language(code:"fr"),   // 4
            Language(code:"zh"),   // 5
        ]
        let diffs = Triff.from(cellsBefore, to: cellsAfter)
        let toMatch: [Diff<Differentiable>] = [
            .moved(entry: Barcode(code: "1011"), fromIndex: 3, toIndex: 0),
            .inserted(entry: Language(code:"en"), index: 1),
            .kept(entry: Language(code:"jp"), fromIndex: 0, toIndex: 2),
            .kept(entry: Language(code:"kr"), fromIndex: 1, toIndex: 3),
            .kept(entry: Language(code:"fr"), fromIndex: 2, toIndex: 4),
            .inserted(entry: Language(code:"zh"), index: 5)]
        XCTAssert(diffs.equals(to: toMatch))
    }

    static var allTests = [
        ("testSuccess", testSuccess),
    ]
}

protocol Model: Differentiable, CustomStringConvertible, Equatable {}

struct Language: Model {
    let code: String

    var description: String {
        return code
    }

    func difference(from other: Differentiable) -> Difference {
        guard let other = other as? Language else { return .entire }
        return other.code == code ? .nothing : .some
    }
}

struct Barcode: Model {
    let code: String

    var description: String {
        return code
    }

    func difference(from other: Differentiable) -> Difference {
        guard let other = other as? Barcode else { return .entire }
        return other.code == code ? .nothing : .some
    }
}

extension Diff: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .deleted(entry, index):
            return "delete(\(entry), \(index))"

        case let .inserted(entry, index):
            return "insert(\(entry), \(index))"

        case let .moved(entry, from, to):
            return "move(\(entry), \(from)->\(to))"

        case let .updated(entry, from, to):
            return "update(\(entry), \(from)->\(to))"

        case let .kept(entry, from, to):
            return "keep(\(entry), \(from)->\(to))"

        case let .nested(entry, from, to, diffs):
            return "nested(\(entry), \(from)->\(to), \(diffs)"
        }
    }
}
