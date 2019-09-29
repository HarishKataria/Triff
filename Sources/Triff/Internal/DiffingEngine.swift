//**************************************************************
//
//  DiffingEngine
//
//  Created by Harish Kataria
//  Copyright © 2019 Harish Kataria. All rights reserved.
//
//**************************************************************

struct DiffingEngine {
    private let left: Diffable
    private let right: Diffable

    private var up: [Int]
    private var down: [Int]
    private var cached: [DiffPosition: Difference]
    private var results: Diffs

    private let config: DiffConfiguration?

    private init(left: Diffable, right: Diffable, config: DiffConfiguration?) {
        self.left = left
        self.right = right
        self.config = config

        let size = left.diffableSegmentCount + right.diffableSegmentCount + 2
        let empty = [Int](repeating: 0, count: size)
        up = empty
        down = empty
        cached = [:]
        results = []
    }

    static func diff(_ left: Diffable, with right: Diffable, using config: DiffConfiguration?) throws -> Diffs {
        var engine = DiffingEngine(left: left, right: right, config: config)
        return try engine.exec()
    }
}

private extension DiffingEngine {
    private mutating func exec() throws -> Diffs {
        try rangeDiff(startLeft: 0, endLeft: left.diffableSegmentCount,
                      startRight: 0, endRight: right.diffableSegmentCount)
        if config?.findMoves ?? true {
            deduceMoves()
        }
        if config?.findNested ?? true {
            try findNested()
        }
        return results
    }

    mutating func deduceMoves() {
        var resultIndex = 0
        while resultIndex < results.count {
            let diff = results[resultIndex]
            switch diff {
            case let .deleted(entry, index):
                let insertedIndex = results.firstIndex(where: { result in
                    if case let .inserted(_, otherIndex) = result,
                        exactMatch(leftIndex: index, rightIndex: otherIndex) {
                        return true
                    }
                    return false
                })
                if var insertedIndex = insertedIndex,
                    case let .inserted(_, dest) = results[insertedIndex] {
                    results.remove(at: resultIndex)
                    if insertedIndex > resultIndex {
                        insertedIndex -= 1
                    }
                    results.remove(at: insertedIndex)
                    results.insert(.moved(entry: entry, fromIndex: index, toIndex: dest), at: insertedIndex)
                    continue
                }
            default:
                break
            }
            resultIndex += 1
        }
    }

    mutating func findNested() throws {
        var hasDiffs = false
        var diffs: Diffs = []
        for diff in results {
            switch diff {
            case let .kept(entry, src, dest):
                let other = right.diffableSegment(at: dest)
                let children = try nested(left: entry, right: other)
                if !children.isEmpty {
                    diffs.append(.nested(entry: entry,
                                         fromIndex: src, toIndex: dest,
                                         diffs: children))
                    hasDiffs = true
                } else if didUpdate(leftIndex: src, rightIndex: dest) {
                    diffs.append(.updated(entry: other, fromIndex: src, toIndex: dest))
                    hasDiffs = true
                } else {
                    diffs.append(diff)
                }
            case let .updated(entry, src, dest):
                diffs.append(diff)
                hasDiffs = true
                let children = try nested(left: entry, right: right.diffableSegment(at: dest))
                if !children.isEmpty {
                    diffs.append(.nested(entry: entry,
                                         fromIndex: src, toIndex: dest,
                                         diffs: children))
                }
            default:
                diffs.append(diff)
                hasDiffs = true
            }
        }
        results = hasDiffs ? diffs : []
    }

    mutating func rangeDiff(startLeft: Int, endLeft: Int, startRight: Int, endRight: Int) throws {
        let middleFragment = try middle(startLeft: startLeft, endLeft: endLeft,
                                        startRight: startRight, endRight: endRight)
        if middleFragment == nil
            || (middleFragment?.start == endLeft && middleFragment?.diagonal == endLeft - endRight)
            || (middleFragment?.end == startLeft && middleFragment?.diagonal == startLeft - startRight) {

            var leftIndex = startLeft
            var rightIndex = startRight
            while leftIndex < endLeft || rightIndex < endRight {
                if leftIndex < endLeft && rightIndex < endRight
                    && equals(leftIndex: leftIndex, rightIndex: rightIndex) {
                    results.append(.kept(entry: right.diffableSegment(at: rightIndex), fromIndex: leftIndex, toIndex: rightIndex))
                    leftIndex += 1
                    rightIndex += 1
                } else {
                    if endLeft - startLeft > endRight - startRight {
                        if leftIndex < endLeft {
                            results.append(.deleted(entry: left.diffableSegment(at: leftIndex), index: leftIndex))
                        }
                        leftIndex += 1
                    } else {
                        if rightIndex < endRight {
                            results.append(.inserted(entry: right.diffableSegment(at: rightIndex), index: rightIndex))
                        }
                        rightIndex += 1
                    }
                }
            }

        } else if let middle = middleFragment {
            try rangeDiff(startLeft: startLeft,
                          endLeft: middle.start,
                          startRight: startRight,
                          endRight: middle.start - middle.diagonal)

            let diff = -middle.diagonal
            for index in middle.start..<middle.end {
                results.append(.kept(entry: right.diffableSegment(at: index + diff), fromIndex: index, toIndex: index + diff))
            }

            try rangeDiff(startLeft: middle.end,
                          endLeft: endLeft,
                          startRight: middle.end - middle.diagonal,
                          endRight: endRight)
        }
    }

    mutating func middle(startLeft: Int, endLeft: Int, startRight: Int, endRight: Int) throws -> Fragment? {
        let leftLength = endLeft - startLeft
        let rightLength = endRight - startRight

        if leftLength <= 0 || rightLength <= 0 {
            return nil
        }

        let delta = leftLength - rightLength
        let totalLength = rightLength + leftLength
        let center = (totalLength % 2 == 0 ? totalLength : totalLength + 1) / 2

        down[1 + center] = startLeft
        up[1 + center] = endLeft + 1

        for offset in 0...center {
            var pos = -offset
            while pos <= offset {
                let index = pos + center
                if pos == -offset || (pos != offset && down[index - 1] < down[index + 1]) {
                    down[index] = down[index + 1]
                } else {
                    down[index] = down[index - 1] + 1
                }

                var posLeft = down[index]
                var posRight = posLeft - startLeft + startRight - pos

                while posLeft < endLeft && posRight < endRight
                    && equals(leftIndex: posLeft, rightIndex: posRight) {
                        posLeft += 1
                        posRight += 1
                        down[index] = posLeft
                }

                if delta % 2 != 0 && delta - offset <= pos && pos <= delta + offset,
                    up[index - delta] <= down[index] { // NOPMD
                    return slice(start: up[index - delta],
                                 diagonal: pos + startLeft - startRight,
                                 endLeft: endLeft, endRight: endRight)
                }

                pos += 2
            }

            pos = delta - offset
            while pos <= delta + offset {
                let index = pos + center - delta
                if pos == delta - offset
                    || (pos != delta + offset && up[index + 1] <= up[index - 1]) {
                    up[index] = up[index + 1] - 1
                } else {
                    up[index] = up[index - 1]
                }

                var posLeft = up[index] - 1
                var posRight = posLeft - startLeft + startRight - pos

                while posLeft >= startLeft && posRight >= startRight
                    && equals(leftIndex: posLeft, rightIndex: posRight) {
                        up[index] = posLeft
                        posLeft -= 1
                        posRight -= 1
                }

                if delta % 2 == 0 && -offset <= pos && pos <= offset,
                    up[index] <= down[index + delta] { // NOPMD
                    return slice(start: up[index],
                                 diagonal: pos + startLeft - startRight,
                                 endLeft: endLeft, endRight: endRight)
                }

                pos += 2
            }
        }

        throw DiffError.unexpected
    }

    mutating func slice(start: Int, diagonal: Int, endLeft: Int, endRight: Int) -> Fragment {
        var end = start
        while end - diagonal < endRight
                && end < endLeft
                && equals(leftIndex: end, rightIndex: end - diagonal) {
                end += 1
        }
        return Fragment(start: start, end: end, diagonal: diagonal)
    }

    mutating func equals(leftIndex: Int, rightIndex: Int) -> Bool {
         return diff(leftIndex: leftIndex, rightIndex: rightIndex) != .entire
    }

    mutating func exactMatch(leftIndex: Int, rightIndex: Int) -> Bool {
        return diff(leftIndex: leftIndex, rightIndex: rightIndex) == .nothing
    }

    mutating func diff(leftIndex: Int, rightIndex: Int) -> Difference {
        let pos = DiffPosition(left: leftIndex, right: rightIndex)
        if let result = cached[pos] {
            return result
        }

        let obj1 = left.diffableSegment(at: leftIndex)
        let obj2 = right.diffableSegment(at: rightIndex)

        let result: Difference
        if let opResult = config?.differentiator?(obj1, obj2) {
            result = opResult
        } else if let leftObj = obj1 as? Differentiable,
                  let rightObj = obj2 as? Differentiable {
            result = leftObj.difference(from: rightObj)
        } else {
            result = .entire
        }

        cached[pos] = result
        return result
    }

    mutating func didUpdate(leftIndex: Int, rightIndex: Int) -> Bool {
        return diff(leftIndex: leftIndex, rightIndex: rightIndex) == .some
    }

    func nested(left: Any, right: Any) throws -> Diffs {
        if let nLeft = left as? NestedDifferentiable,
            let nRight = right as? NestedDifferentiable {
           return try nLeft.nestedDifference(from: nRight, config: config)
        }
        return []
    }

    struct Fragment {
        let start: Int
        let end: Int
        let diagonal: Int
    }

    struct DiffPosition: Hashable {
        let left: Int
        let right: Int
    }

    enum DiffError: Error {
        case unexpected
    }
}
