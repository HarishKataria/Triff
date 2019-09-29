//**************************************************************
//
//  Triff
//
//  Created by Harish Kataria
//  Copyright © 2019 Harish Kataria. All rights reserved.
//
//**************************************************************

public struct Triff {
    public static func from(_ first: [Differentiable], to second: [Differentiable]) -> [Diff<Differentiable>] {
        let left = DiffableFactory.create(from: first)
        let right = DiffableFactory.create(from: second)
        let config = DefaultConfiguration()
        let result = try? left.diff(against: right, using: config)
        return result?.compactMap({ input -> Diff<Differentiable>? in
            input.map()
        }) ?? []
    }
}
