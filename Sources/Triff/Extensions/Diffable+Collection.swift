//**************************************************************
//
//  Diff+Collection
//
//  Created by Harish Kataria
//  Copyright © 2019 Harish Kataria. All rights reserved.
//
//**************************************************************

public extension Collection where Element: Differentiable {
    func diff(_ other: Self,
              findMoves: Bool = true,
              findNested: Bool = true) -> [Diff<Element>] {
        let left = DiffableFactory.create(from: self)
        let right = DiffableFactory.create(from: other)
        let config = DefaultConfiguration(findMoves: findMoves, findNested: findNested, differentiator: nil)
        let result = try? left.diff(against: right, using: config)
        return result?.compactMap { $0.map() } ?? []
    }
}


public extension Collection where Element == Diff<Differentiable> {
    func equals(to other: Self) -> Bool {
        guard count == other.count else {
            return false
        }
        var iterator1 = makeIterator()
        var iterator2 = other.makeIterator()
        while true {
            let item1 = iterator1.next()
            let item2 = iterator2.next()
            if item1 == nil && item2 == nil {
                break
            }
            if  let item1 = item1, let item2 = item2,
                item1.equals(to: item2) {
                continue
            } else {
                return false
            }
        }
        return true
    }
}

public extension Collection where Element: Equatable {
    func diff(equatable other: Self,
              config: DiffConfiguration) -> [Diff<Element>] {
        let left = DiffableFactory.create(from: self)
        let right = DiffableFactory.create(from: other)
        let result = try? left.diff(against: right, using: config)
        return result?.compactMap { $0.map() } ?? []
    }

    func diff(equatable other: Self,
              findMoves: Bool = true,
              findNested: Bool = true,
              using compare: ((Element, Element) -> Difference)? = nil) -> [Diff<Element>] {
        let left = DiffableFactory.create(from: self)
        let right = DiffableFactory.create(from: other)
        let config = DefaultConfiguration(findMoves: findMoves, findNested: findNested) { left, right in
            guard let left = left as? Element, let right = right as? Element else {
                return nil
            }
            if let result = compare?(left, right) {
                return result
            }
            return left == right ? .nothing : .entire
        }
        let result = try? left.diff(against: right, using: config)
        return result?.compactMap { $0.map() } ?? []
    }
}

public struct DiffableFactory {
    public static func create<CollectionType>(from collection: CollectionType) -> Diffable
        where CollectionType: Collection {
        if let collection = collection as? Diffable {
            return collection
        }
        return DiffableCollection(collection: collection)
    }
}

private struct DiffableCollection<CollectionType>: Diffable
        where CollectionType: Collection {
    let collection: CollectionType

    func diffableSegment(at index: Int) -> Any {
        if let index = index as? CollectionType.Index {
            return collection[index]
        }
        let typedIndex = collection.index(collection.startIndex, offsetBy: index)
        return collection[typedIndex]
    }

    var diffableSegmentCount: Int {
        return collection.count
    }
}

public extension Diffable {
    func diff(against other: Diffable, using config: DiffConfiguration?) throws -> Diffs {
        return try DiffingEngine.diff(self, with: other, using: config)
    }
}
