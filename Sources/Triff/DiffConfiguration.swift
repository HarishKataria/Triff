//**************************************************************
//
//  DiffConfiguration
//
//  Created by Harish Kataria
//  Copyright © 2019 Harish Kataria. All rights reserved.
//
//**************************************************************

public protocol DiffConfiguration {
    var findMoves: Bool { get }
    var findNested: Bool { get }
    var differentiator: Differentiator? { get }
}

public struct DefaultConfiguration: DiffConfiguration {
    public let findMoves: Bool
    public let findNested: Bool
    public let differentiator: Differentiator?

    public init(findMoves: Bool = true,
                findNested: Bool = false,
                differentiator: Differentiator? = nil) {
        self.findMoves = findMoves
        self.findNested = findNested
        self.differentiator = differentiator
    }
}
