//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension PersistentSet {
  /// Removes the elements of the given set from this set.
  ///
  ///     var a: PersistentSet = [1, 2, 3, 4]
  ///     let b: PersistentSet = [0, 2, 4, 6]
  ///     a.subtract(b)
  ///     // `a` is now some permutation of `[1, 3]`
  ///
  /// - Parameter other: An arbitrary set of elements.
  /// - Complexity: Expected complexity is O(`self.count` + `other.count`) in
  ///     the worst case, if `Element` properly implements hashing.
  ///     However, the implementation is careful to make the best use of
  ///     hash tree structure to minimize work when possible, e.g. by linking
  ///     parts of the input trees directly into the result.
  @inlinable
  public mutating func subtract(_ other: Self) {
    self = subtracting(other)
  }

  @inlinable
  public mutating func subtract<Value>(
    _ other: PersistentDictionary<Element, Value>.Keys
  ) {
    self = subtracting(other)
  }

  @inlinable
  public mutating func subtract<S: Sequence>(_ other: S)
  where S.Element == Element {
    self = subtracting(other)
  }
}
