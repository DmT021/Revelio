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

/// Flags for nominal type context descriptors. These values are used as the
/// kindSpecificFlags of the ContextDescriptorFlags for the type.
public struct TypeContextDescriptorFlags {
  var value: UInt16

  // All of these values are bit offsets or widths.
  // Generic flags build upwards from 0.
  // Type-specific flags build downwards from 15.

  /// Whether there's something unusual about how the metadata is
  /// initialized.
  ///
  /// Meaningful for all type-descriptor kinds.
  var metadataInitialization: UInt8 {
    UInt8(value & 3)
  }

  /// Set if the type has extended import information.
  ///
  /// If true, a sequence of strings follow the null terminator in the
  /// descriptor, terminated by an empty string (i.e. by two null
  /// terminators in a row).  See TypeImportInfo for the details of
  /// these strings and the order in which they appear.
  ///
  /// Meaningful for all type-descriptor kinds.
  public var hasImportInfo: Bool {
    value & 4 != 0
  }

  /// Set if the generic type descriptor has a pointer to a list of canonical
  /// prespecializations, or the non-generic type descriptor has a pointer to
  /// its singleton metadata.
  public var hasCanonicalMetadataPrespecializationsOrSingletonMetadataPointer: Bool {
    value & 8 != 0
  }

  /// Set if the metadata contains a pointer to a layout string
  public var hasLayoutString: Bool {
    value & 0x10 != 0
  }

  /// WARNING: 5 is the last bit!

  // Type-specific flags:

  public var classHasDefaultOverrideTable: Bool {
    value & 0x40 != 0
  }

  /// Set if the class is an actor.
  ///
  /// Only meaningful for class descriptors.
  public var classIsActor: Bool {
    value & 0x80 != 0
  }

  /// Set if the class is a default actor class.  Note that this is
  /// based on the best knowledge available to the class; actor
  /// classes with resilient superclassess might be default actors
  /// without knowing it.
  ///
  /// Only meaningful for class descriptors.
  public var classIsDefaultActor: Bool {
    value & 0x100 != 0
  }

  /// The kind of reference that this class makes to its resilient superclass
  /// descriptor.  A TypeReferenceKind.
  ///
  /// Only meaningful for class descriptors.
  public var classResilientSuperclassReferenceKind: TypeReferenceKind? {
    TypeReferenceKind(rawValue: UInt8((value >> 9) & 7))
  }

  /// Whether the immediate class members in this metadata are allocated
  /// at negative offsets.  For now, we don't use this.
  public var classAreImmediateMembersNegative: Bool {
    value & 0x1000 != 0
  }

  /// Set if the context descriptor is for a class with resilient ancestry.
  ///
  /// Only meaningful for class descriptors.
  public var classHasResilientSuperclass: Bool {
    value & 0x2000 != 0
  }

  /// Set if the context descriptor includes metadata for dynamically
  /// installing method overrides at metadata instantiation time.
  public var classHasOverrideTable: Bool {
    value & 0x4000 != 0
  }

  /// Set if the context descriptor includes metadata for dynamically
  /// constructing a class's vtables at metadata instantiation time.
  ///
  /// Only meaningful for class descriptors.
  public var classHasVTable: Bool {
    value & 0x8000 != 0
  }
}

/// Kinds of type metadata/protocol conformance records.
/// Only 3 bits
public enum TypeReferenceKind: UInt8 {
  /// The conformance is for a nominal type referenced directly;
  /// getTypeDescriptor() points to the type context descriptor.
  case directTypeDescriptor = 0

  /// The conformance is for a nominal type referenced indirectly;
  /// getTypeDescriptor() points to the type context descriptor.
  case indirectTypeDescriptor = 1

  /// The conformance is for an Objective-C class that should be looked up
  /// by class name.
  case directObjCClassName = 2

  /// The conformance is for an Objective-C class that has no nominal type
  /// descriptor.
  /// getIndirectObjCClass() points to a variable that contains the pointer to
  /// the class object, which then requires a runtime call to get metadata.
  ///
  /// On platforms without Objective-C interoperability, this case is
  /// unused.
  case indirectObjCClass = 3
}
