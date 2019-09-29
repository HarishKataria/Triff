//**************************************************************
//
//  Diff+UITableView
//
//  Created by Harish Kataria
//  Copyright © 2019 Harish Kataria. All rights reserved.
//
//**************************************************************

#if canImport(UIKit)
import UIKit

public extension UITableView {
    func update<Element>(changes diffs: [Diff<Element>],
                         animation: UITableView.RowAnimation = .fade,
                         onIndexUpdated: (() -> Void),
                         completion: @escaping ((Bool) -> Void)) {
        guard !diffs.isEmpty else {
            onIndexUpdated()
            completion(false)
            return
        }

        if #available(iOS 11.0, *) {
            performBatchUpdates({
                performUpdates(with: DiffIndexes.from(diffs: diffs), animation: animation)
                onIndexUpdated()
            }, completion: completion)
        } else {
            beginUpdates()
            performUpdates(with: DiffIndexes.from(diffs: diffs), animation: animation)
            onIndexUpdated()
            endUpdates()
            completion(true)
        }
    }

    private func performUpdates(with indexes: DiffIndexes, animation: UITableView.RowAnimation) {
        if !indexes.deletedSet.isEmpty {
            deleteSections(indexes.deletedSet, with: animation)
        }
        if !indexes.insertedSet.isEmpty {
            insertSections(indexes.insertedSet, with: animation)
        }

        if !indexes.deletedPaths.isEmpty {
            deleteRows(at: indexes.deletedPaths, with: animation)
        }
        if !indexes.insertedPaths.isEmpty {
            insertRows(at: indexes.insertedPaths, with: animation)
        }

        if !indexes.movedSet.isEmpty {
            indexes.movedSet.forEach { moveSection($0.0, toSection: $0.1) }
        }
        if !indexes.movedPaths.isEmpty {
            indexes.movedPaths.forEach { moveRow(at: $0.0, to: $0.1) }
        }

        if !indexes.updatedPaths.isEmpty {
            reloadRows(at: indexes.updatedPaths, with: animation)
        }
        if !indexes.updatedSet.isEmpty {
            reloadSections(indexes.updatedSet, with: animation)
        }
    }
}

private struct DiffIndexes {
    let deletedSet: IndexSet
    let insertedSet: IndexSet
    let movedSet: [(Int, Int)]
    let updatedSet: IndexSet
    let deletedPaths: [IndexPath]
    let insertedPaths: [IndexPath]
    let movedPaths: [(IndexPath, IndexPath)]
    let updatedPaths: [IndexPath]
}

private extension DiffIndexes {
    static func from<Element>(diffs: [Diff<Element>]) -> DiffIndexes {
        var deletionSet = IndexSet()
        var insertionSet = IndexSet()
        var moveSet: [(Int, Int)] = []
        var updateSet = IndexSet()
        var deletionPaths: [IndexPath] = []
        var insertedPaths: [IndexPath] = []
        var movedPaths: [(IndexPath, IndexPath)] = []
        var updatedPaths: [IndexPath] = []

        for diff in diffs {
            switch diff {
            case let .deleted(_, index):
                deletionSet.insert(index)

            case let .inserted(_, index):
                insertionSet.insert(index)

            case let .updated(_, from, _):
                updateSet.insert(from)

            case let .moved(_, from, to):
                moveSet.append((from, to))

            case let .nested(_, src, dest, children):
                for row in children {
                    switch row {
                    case let .deleted(_, index):
                        deletionPaths.append(IndexPath(row: index, section: src))
                    case let .inserted(_, index):
                        insertedPaths.append(IndexPath(row: index, section: dest))
                    case let .updated(_, from, _):
                        updatedPaths.append(IndexPath(row: from, section: src))
                    case let .moved(_, from, to):
                        movedPaths.append((IndexPath(row: from, section: src),
                                         IndexPath(row: to, section: dest)))
                    default:
                        break
                    }
                }
            default:
                break
            }
        }
        return DiffIndexes(deletedSet: deletionSet,
                           insertedSet: insertionSet,
                           movedSet: moveSet,
                           updatedSet: updateSet,
                           deletedPaths: deletionPaths,
                           insertedPaths: insertedPaths,
                           movedPaths: movedPaths,
                           updatedPaths: updatedPaths)
    }
}

#endif
