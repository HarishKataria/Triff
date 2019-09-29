//**************************************************************
//
//  Diff+Equatable
//
//  Created by Harish Kataria
//  Copyright © 2019 Harish Kataria. All rights reserved.
//
//**************************************************************

extension Diff: Equatable where Element: Differentiable {
    public static func == (lhs: Diff<Element>, rhs: Diff<Element>) -> Bool {
        guard let left: Diff<Differentiable> = lhs.map(),
              let right: Diff<Differentiable> = rhs.map() else {
                return false
        }
        return left.equals(to: right)
    }
}

extension Diff where Element == Differentiable {
    func equals(to other: Diff<Element>) -> Bool {
        switch (self, other) {
        case let (.deleted(elementLeft, indexLeft), .deleted(elementRight, indexRight)),
             let (.inserted(elementLeft, indexLeft), .inserted(elementRight, indexRight)):
            return elementLeft.difference(from: elementRight) == .nothing
                && indexLeft == indexRight

        case let (.kept(elementLeft, srcLeft, destLeft),
                  .kept(elementRight, srcRight, destRight)):
            return elementLeft.difference(from: elementRight) == .nothing
                && srcLeft == srcRight
                && destLeft == destRight

        case let (.nested(elementLeft, srcLeft, destLeft, childLeft),
                  .nested(elementRight, srcRight, destRight, childRight)):
            return elementLeft.difference(from: elementRight) == .nothing
                && srcLeft == srcRight
                && destLeft == destRight
                && compare(left: childLeft, right: childRight)

        case let (.moved(elementLeft, srcLeft, destLeft),
                  .moved(elementRight, srcRight, destRight)):
            return elementLeft.difference(from: elementRight) == .nothing
                && srcLeft == srcRight
                && destLeft == destRight

        default:
            return false
        }
    }

    private func compare(left: Diffs, right: Diffs) -> Bool {
        if left.count != right.count {
            return false
        }
        for index in 0..<left.count {
            if let leftValue: Diff<Differentiable> = left[index].map(),
                let rightValue: Diff<Differentiable> = right[index].map(),
                !leftValue.equals(to: rightValue) {
                return false
            }
        }
        return true
    }
}

public extension Diff {
    func map<MappedType>() -> Diff<MappedType>? {
        switch self {
        case let .deleted(entry, index):
            guard let element = entry as? MappedType else { return nil }
            return .deleted(entry: element, index: index)

        case let .inserted(entry, index):
            guard let element = entry as? MappedType else { return nil }
            return .inserted(entry: element, index: index)

        case let .kept(entry, src, dest):
            guard let element = entry as? MappedType else { return nil }
            return .kept(entry: element, fromIndex: src, toIndex: dest)

        case let .nested(entry, src, dest, diffs):
            guard let element = entry as? MappedType else { return nil }
            return .nested(entry: element, fromIndex: src, toIndex: dest, diffs: diffs)

        case let .moved(entry, src, dest):
            guard let element = entry as? MappedType else { return nil }
            return .moved(entry: element, fromIndex: src, toIndex: dest)

        case let .updated(entry, src, dest):
            guard let element = entry as? MappedType else { return nil }
            return .updated(entry: element, fromIndex: src, toIndex: dest)
        }
    }
}
