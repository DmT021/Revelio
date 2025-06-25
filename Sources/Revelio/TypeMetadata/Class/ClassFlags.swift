// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

/// Swift class flags.
/// These flags are valid only when isTypeMetadata().
/// When !isTypeMetadata() these flags will collide with other Swift ABIs.
public struct ClassFlags {
  var value: UInt32

  /// Is this a Swift class from the Darwin pre-stable ABI?
  /// This bit is clear in stable ABI Swift classes.
  /// The Objective-C runtime also reads this bit.
  public var isSwiftPreStableABI: Bool { value & 0x1 != 0 }

  /// Does this class use Swift refcounting?
  public var usesSwiftRefcounting: Bool { value & 0x2 != 0 }

  /// Has this class a custom name, specified with the @objc attribute?
  public var hasCustomObjCName: Bool { value & 0x4 != 0 }

  /// Whether this metadata is a specialization of a generic metadata pattern
  /// which was created during compilation.
  public var isStaticSpecialization: Bool { value & 0x8 != 0 }

  /// Whether this metadata is a specialization of a generic metadata pattern
  /// which was created during compilation and made to be canonical by
  /// modifying the metadata accessor.
  public var isCanonicalStaticSpecialization: Bool { value & 0x10 != 0 }
}
