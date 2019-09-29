//**************************************************************
//
//  BinaryDiff
//
//  Created by Harish Kataria
//  Copyright © 2019 Harish Kataria. All rights reserved.
//
//**************************************************************

public enum BinaryDiff<Element> {
    case add(element: Element, atIndex: Int)
    case remove(index: Int)
}

public extension Diff {
    static func reduce(_ diffs: [Diff<Element>]) -> [BinaryDiff<Element>] {
        var result: [BinaryDiff<Element>] = []
        for diff in diffs {
            switch diff {
            case let .inserted(entry, index):
                result.append(.add(element: entry, atIndex: index))

            case let .deleted(_, index):
                result.append(.remove(index: index))

            case let .moved(entry, src, dest):
                result.append(.remove(index: src))
                result.append(.add(element: entry, atIndex: dest))

            case .kept, .updated, .nested:
                break
            }
        }
        return BinaryDiff.sort(result)
    }
}

extension BinaryDiff: Equatable where Element: Equatable {
    public static func == (lhs: BinaryDiff<Element>, rhs: BinaryDiff<Element>) -> Bool {
        switch (lhs, rhs) {
        case let (.remove(indexLeft), .remove(indexRight)):
            return indexLeft == indexRight
        case let (.add(elementLeft, indexLeft), .add(elementRight, indexRight)):
            return indexLeft == indexRight && elementLeft == elementRight
        default:
            return false
        }
    }
}

public extension BinaryDiff {
    static func sort(_ diffs: [BinaryDiff<Element>]) -> [BinaryDiff<Element>] {
        return diffs.sorted { lhs, rhs in
            switch (lhs, rhs) {
            case let (.add(_, index1), .add(_, index2)):
                return index1 < index2
            case let (.remove(index1), .remove(index2)):
                return index1 > index2
            case (.remove, .add):
                return true
            default:
                return false
            }
        }
    }
}

public extension RangeReplaceableCollection {
    func apply(diffs: [BinaryDiff<Element>]) -> Self {
        var result = self
        for diff in diffs {
            switch diff {
            case let .remove(offset):
                result.remove(at: result.index(result.startIndex, offsetBy: offset))

            case let .add(entry, offset):
                if offset >= result.count {
                    result.append(entry)
                } else {
                    result.insert(entry, at: result.index(result.startIndex, offsetBy: offset))
                }
            }
        }
        return result
    }
}
