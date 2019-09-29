//**************************************************************
//
//  Differentiable
//
//  Created by Harish Kataria
//  Copyright © 2019 Harish Kataria. All rights reserved.
//
//**************************************************************

public protocol Differentiable {
    func difference(from: Differentiable) -> Difference
}

public typealias Differentiator = (Any, Any) -> Difference?

public extension Equatable where Self: Differentiable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.difference(from: rhs) == .nothing
    }
}
