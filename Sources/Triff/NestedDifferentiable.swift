//**************************************************************
//
//  NestedDifferentiable
//
//  Created by Harish Kataria
//  Copyright © 2019 Harish Kataria. All rights reserved.
//
//**************************************************************

public protocol NestedDifferentiable {
    func nestedDifference(from: NestedDifferentiable,
                          config: DiffConfiguration?) throws -> Diffs
}
