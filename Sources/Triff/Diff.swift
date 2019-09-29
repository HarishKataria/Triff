//**************************************************************
//
//  Diff
//
//  Created by Harish Kataria
//  Copyright © 2019 Harish Kataria. All rights reserved.
//
//**************************************************************

public enum Diff<Element> {
    case deleted(entry: Element, index: Int)
    case inserted(entry: Element, index: Int)

    case moved(entry: Element, fromIndex: Int, toIndex: Int)
    case updated(entry: Element, fromIndex: Int, toIndex: Int)

    case kept(entry: Element, fromIndex: Int, toIndex: Int)
    case nested(entry: Element, fromIndex: Int, toIndex: Int, diffs: Diffs)
}

public typealias AnyDiff = Diff<Any>
public typealias Diffs = [AnyDiff]
