// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

public enum GenericParamKind {
  /// A type parameter.
  case type

  /// A type parameter pack.
  case typePack

  /// A value type parameter.
  case value

  init?(value: UInt8) {
    switch value {
    case 0: self = .type
    case 1: self = .typePack
    case 2: self = .value
    case let value where value > 0x3F:
      assertionFailure()
      fallthrough
    default:
      return nil
    }
  }
}

public struct GenericParamDescriptor {
  var value: UInt8

  public var kind: GenericParamKind? {
    GenericParamKind(value: value & 0x3F)
  }

  public var hasKeyArgument: Bool {
    value & 0x80 != 0
  }
}
