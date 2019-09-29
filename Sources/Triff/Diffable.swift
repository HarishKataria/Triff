//**************************************************************
//
//  Diffable
//
//  Created by Harish Kataria
//  Copyright © 2019 Harish Kataria. All rights reserved.
//
//**************************************************************

public protocol Diffable {
    func diff(against: Diffable, using: DiffConfiguration?) throws -> Diffs
    func diffableSegment(at: Int) -> Any
    var diffableSegmentCount: Int { get }
}
