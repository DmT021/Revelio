// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

/// Kinds of context descriptor.
///
/// include/swift/ABI/MetadataValues.h
public enum ContextDescriptorKind {
  case module
  case `extension`
  case anonymous
  case `protocol`
  case opaqueType
  case `class`
  case `struct`
  case `enum`
  case unknown

  init(rawValue: UInt8) {
    self = switch rawValue {
    case 0: .module
    case 1: .extension
    case 2: .anonymous
    case 3: .protocol
    case 4: .opaqueType
    case 16: .class
    case 17: .struct
    case 18: .enum
    default: .unknown
    }
  }
}

/// Common flags stored in the first 32-bit word of any context descriptor.
///
/// include/swift/ABI/MetadataValues.h
public struct ContextDescriptorFlags {
  public var value: UInt32

  /// The kind of context this descriptor describes.
  public var kind: ContextDescriptorKind {
    ContextDescriptorKind(rawValue: UInt8(value & 0x1F))
  }

  /// Whether the context being described is generic.
  public var isGeneric: Bool {
    value & 0x80 != 0
  }

  /// Whether this is a unique record describing the referenced context.
  public var isUnique: Bool {
    value & 0x40 != 0
  }

  /// Whether the context has information about invertible protocols, which
  /// will show up as a trailing field in the context descriptor.
  public var hasInvertibleProtocols: Bool {
    value & 0x20 != 0
  }

  /// The most significant two bytes of the flags word, which can have
  /// kind-specific meaning.
  var kindSpecificFlags: UInt16 {
    UInt16((value >> 16) & 0xFFFF)
  }
}
