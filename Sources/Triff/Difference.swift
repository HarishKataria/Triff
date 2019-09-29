//**************************************************************
//
//  Difference
//
//  Created by Harish Kataria
//  Copyright © 2019 Harish Kataria. All rights reserved.
//
//**************************************************************

public enum Difference: Equatable {
    /// no differences between inputs
    case nothing
    /// some differences between inputs
    case some
    /// entire inputs are different
    case entire
}

public extension Difference {
    func union(_ other: Difference) -> Difference {
        switch (self, other) {
        case (.nothing, .nothing):
            return .nothing
        case (.entire, _), (_, .entire):
            return .entire
        case (.some, _), (_, .some):
            return .some
        }
    }
}
