//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Collections open source project
//
// Copyright (c) 2019 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

public struct PersistentDictionary<Key, Value> where Key: Hashable {
  var _root: _Node

  internal init(_root: _Node) {
    self._root = _root
  }
}

extension PersistentDictionary {
  public init() {
    self.init(_root: _Node())
  }

  @inlinable
  public init(_ other: PersistentDictionary<Key, Value>) {
    self = other
  }

  @inlinable
  @inline(__always)
  public init<S: Sequence>(
    uniqueKeysWithValues keysAndValues: S
  ) where S.Element == (Key, Value) {
    self.init()
    for (key, value) in keysAndValues {
      let unique = updateValue(value, forKey: key) == nil
      precondition(unique, "Duplicate key: '\(key)'")
    }
  }

  @inlinable
  @inline(__always)
  public init<Keys: Sequence, Values: Sequence>(
    uniqueKeys keys: Keys,
    values: Values
  ) where Keys.Element == Key, Values.Element == Value {
    self.init(uniqueKeysWithValues: zip(keys, values))
  }

  public subscript(key: Key) -> Value? {
    get {
      return _get(key)
    }
    mutating set(optionalValue) {
      if let value = optionalValue {
        updateValue(value, forKey: key)
      } else {
        removeValue(forKey: key)
      }
    }
  }

  public subscript(
    key: Key,
    default defaultValue: @autoclosure () -> Value
  ) -> Value {
    get {
      return _get(key) ?? defaultValue()
    }
    mutating set(value) {
      updateValue(value, forKey: key)
    }
  }

  public func contains(_ key: Key) -> Bool {
    _root.containsKey(key, _HashPath(key))
  }

  func _get(_ key: Key) -> Value? {
    _root.get(key, _HashPath(key))
  }

  /// Returns the index for the given key.
  public func index(forKey key: Key) -> Index? {
    _root.index(forKey: key, _HashPath(key), 0)
  }

  @discardableResult
  public mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
    let isUnique = isKnownUniquelyReferenced(&self._root)

    var effect = _DictionaryEffect<Value>()
    let newRoot = _root.updateOrUpdating(
      isUnique, (key, value), _HashPath(key), &effect)

    if effect.modified {
      self._root = newRoot
    }

    // Note, always tracking discardable result negatively impacts batch use cases
    return effect.previousValue
  }

  // fluid/immutable API
  public func updatingValue(_ value: Value, forKey key: Key) -> Self {
    var effect = _DictionaryEffect<Value>()
    let newRoot = _root.updateOrUpdating(
      false, (key, value), _HashPath(key), &effect)

    guard effect.modified else { return self }
    return Self(_root: newRoot)
  }

  @discardableResult
  public mutating func removeValue(forKey key: Key) -> Value? {
    let isUnique = isKnownUniquelyReferenced(&self._root)

    var effect = _DictionaryEffect<Value>()
    let newRoot = _root.removeOrRemoving(
      isUnique, key, _HashPath(key), &effect)

    if effect.modified {
      self._root = newRoot
    }

    // Note, always tracking discardable result negatively impacts batch use cases
    return effect.previousValue
  }

  // fluid/immutable API
  public func removingValue(forKey key: Key) -> Self {
    var effect = _DictionaryEffect<Value>()
    let newRoot = _root.removeOrRemoving(
      false, key, _HashPath(key), &effect)

    if effect.modified {
      return Self(_root: newRoot)
    }
    return self
  }
}

