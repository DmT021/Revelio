// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

import RevelioC

public protocol ClassDescriptor: TypeContextDescriptor {
  var numFields: Int { get }
  var fieldOffsetVectorOffset: Int { get }
}

public struct ClassDescriptorPointer: ClassDescriptor {
  typealias Pointee = _ClassDescriptor

  var ptr: UnsafePointer<Pointee>

  init(ptr: UnsafePointer<Pointee>) {
    self.ptr = ptr
  }

  init(rawPtr: UnsafeRawPointer) {
    self.init(ptr: rawPtr.assumingMemoryBound(to: Pointee.self))
  }

  var base: TypeContextDescriptorPointer {
    TypeContextDescriptorPointer(ptr: ptr.pointer(to: \.base)!)
  }

  // ContextDescriptor

  public var flags: ContextDescriptorFlags { base.flags }

  public var parent: ContextDescriptorPointer? { base.parent }

  // TypeContextDescriptor

  public var name: String { base.name }

  public var typeFlags: TypeContextDescriptorFlags { base.typeFlags }

  public var genericContext: TypeGenericContextDescriptorHeaderPointer? {
    guard flags.isGeneric else {
      return nil
    }
    let genericContextOffset = MemoryLayout<Pointee>.size
    return TypeGenericContextDescriptorHeaderPointer(
      rawPtr: UnsafeRawPointer(ptr).advanced(by: genericContextOffset)
    )
  }

  var genericParameterDescriptors: UnsafeBufferPointer<GenericParamDescriptor>? {
    // it's immediately after genericContext
    guard let genericContext else {
      return nil
    }
    return UnsafeBufferPointer(
      start: genericContext.ptr.end
        .assumingMemoryBound(to: GenericParamDescriptor.self),
      count: genericContext.numParams
    )
  }

  /// Return the offset of the start of generic arguments in the nominal
  /// type's metadata. The returned value is measured in words.
  var genericArgumentOffset: Int32? {
    if typeFlags.classHasResilientSuperclass {
      var resilientImmediateMembersOffset: Int32? {
        // assert(description->hasResilientSuperclass());
        let cachedResilientMetadataBoundsPtr = ptr.pointee
          .metadataNegativeSizeInWordsOrResilientMetadataBounds
          .resilientMetadataBounds
          .pointer(from: ptr.pointer(to: \.metadataNegativeSizeInWordsOrResilientMetadataBounds)!)

        // try get the cached value
        if let immediateMembersOffset
          = cachedResilientMetadataBoundsPtr?.pointee.tryGetImmediateMembersOffset()
        {
          return Int32(immediateMembersOffset / MemoryLayout<UnsafeRawPointer>.size)
        }

        // If there's no value in the cache the runtime will
        // calculate it based on metadata bounds.
        // Unfortunatelly if the class has a resilient superclass
        // we would need to know it for the calculation.
        // Even more unfortunatelly `TargetResilientSuperclass`
        // is positioned after the objects of `TrailingGenericContextObjects`.
        // Newer runtimes may add objects to `TrailingGenericContextObjects`.
        // So the position of `TargetResilientSuperclass` can't be reliably
        // calculated for future runtimes.
        // So we rely solely on the cached immediateMembersOffset.
        return nil
      }
      return resilientImmediateMembersOffset
    } else {
      let bounds = nonResilientMetadataBounds
      return Int32(bounds.immediateMembersOffset / MemoryLayout<UnsafeRawPointer>.size)
    }
  }

  // ClassDescriptor

  public var numFields: Int {
    Int(ptr.pointee.numFields)
  }

  public var fieldOffsetVectorOffset: Int {
    Int(ptr.pointee.fieldOffsetVectorOffset)
  }

  public var numImmediateMembers: Int {
    Int(ptr.pointee.numImmediateMembers)
  }

  var metadataBounds: _ClassMetadataBounds? {
    if typeFlags.classHasResilientSuperclass {
      let cachedResilientMetadataBoundsPtr = ptr.pointee
        .metadataNegativeSizeInWordsOrResilientMetadataBounds
        .resilientMetadataBounds
        .pointer(from: ptr.pointer(to: \.metadataNegativeSizeInWordsOrResilientMetadataBounds)!)

      return cachedResilientMetadataBoundsPtr?.pointee.tryGet()
    } else {
      return nonResilientMetadataBounds
    }
  }

  var nonResilientMetadataBounds: _ClassMetadataBounds {
    assert(!typeFlags.classHasResilientSuperclass)
    /// Given that this class is known to not have a resilient superclass
    /// return its metadata bounds.
    let metadataNegativeSizeInWords = ptr.pointee
      .metadataNegativeSizeInWordsOrResilientMetadataBounds
      .metadataNegativeSizeInWords
    let metadataPositiveSizeInWords = ptr.pointee
      .metadataPositiveSizeInWordsOrExtraClassFlags
      .metadataPositiveSizeInWords

    /// Given that this class is known to not have a resilient superclass,
    /// return the offset of its immediate members in words.
    var nonResilientImmediateMembersOffset: Int32 {
      // assert(!hasResilientSuperclass());
      if typeFlags.classAreImmediateMembersNegative {
        -Int32(metadataNegativeSizeInWords)
      } else {
        Int32(Int(metadataPositiveSizeInWords) - numImmediateMembers)
      }
    }
    return _ClassMetadataBounds(
      base: _MetadataBounds(
        negativeSizeInWords: metadataNegativeSizeInWords,
        positiveSizeInWords: metadataPositiveSizeInWords
      ),
      immediateMembersOffset: Int(nonResilientImmediateMembersOffset) *
        MemoryLayout<UnsafeRawPointer>.size
    )
  }
}

extension ClassDescriptorPointer: Hashable {}

// include/swift/ABI/Metadata.h
struct _ClassDescriptor {
  /// Union of `MetadataNegativeSizeInWords` and `ResilientMetadataBounds`
  struct MetadataNegativeSizeInWordsOrResilientMetadataBounds {
    var value: UInt32

    /// If this descriptor does not have a resilient superclass, this is the
    /// negative size of metadata objects of this class (in words).
    var metadataNegativeSizeInWords: UInt32 { value }

    /// If this descriptor has a resilient superclass, this is a reference
    /// to a cache holding the metadata's extents.
    var resilientMetadataBounds: RelativeDirectPointer<Int32, _StoredClassMetadataBounds> {
      RelativeDirectPointer(relativeOffset: Int32(bitPattern: value))
    }
  }

  /// Union of `MetadataPositiveSizeInWords` and `ExtraClassFlags`
  struct MetadataPositiveSizeInWordsOrExtraClassFlags {
    var value: UInt32

    /// If this descriptor does not have a resilient superclass, this is the
    /// positive size of metadata objects of this class (in words).
    var metadataPositiveSizeInWords: UInt32 { value }

    /// Otherwise, these flags are used to do things like indicating
    /// the presence of an Objective-C resilient class stub.
    var extraClassFlags: ExtraClassDescriptorFlags {
      ExtraClassDescriptorFlags(value: value)
    }
  }

  var base: _TypeContextDescriptor

  /// The type of the superclass, expressed as a mangled type name that can
  /// refer to the generic arguments of the subclass type.
  //  TargetRelativeDirectPointer<Runtime, const char> SuperclassType;
  var superclassType: RelativeDirectPointer<Int32, CChar>

  var metadataNegativeSizeInWordsOrResilientMetadataBounds: MetadataNegativeSizeInWordsOrResilientMetadataBounds

  var metadataPositiveSizeInWordsOrExtraClassFlags: MetadataPositiveSizeInWordsOrExtraClassFlags

  /// The number of additional members added by this class to the class
  /// metadata.  This data is opaque by default to the runtime, other than
  /// as exposed in other members; it's really just
  /// NumImmediateMembers * sizeof(void*) bytes of data.
  ///
  /// Whether those bytes are added before or after the address point
  /// depends on areImmediateMembersNegative().
  //  uint32_t NumImmediateMembers; // ABI: could be uint16_t?
  var numImmediateMembers: UInt32

  /// The number of stored properties in the class, not including its
  /// superclasses. If there is a field offset vector, this is its length.
  //  uint32_t NumFields;
  var numFields: UInt32

  /// The offset of the field offset vector for this class's stored
  /// properties in its metadata, in words. 0 means there is no field offset
  /// vector.
  ///
  /// If this class has a resilient superclass, this offset is relative to
  /// the size of the resilient superclass metadata. Otherwise, it is
  /// absolute.
  //  uint32_t FieldOffsetVectorOffset;
  var fieldOffsetVectorOffset: UInt32
}

struct _StoredClassMetadataBounds {
  /// The offset to the immediate members.  This value is in bytes so that
  /// clients don't have to sign-extend it.

  /// It is not necessary to use atomic-ordered loads when accessing this
  /// variable just to read the immediate-members offset when drilling to
  /// the immediate members of an already-allocated metadata object.
  /// The proper initialization of this variable is always ordered before
  /// any allocation of metadata for this class.
  //  std::atomic<StoredPointerDifference> ImmediateMembersOffset;
  typealias StoredPointerDifference = Int // ptrdiff_t
  var immediateMembersOffset: StoredPointerDifference // TODO: make it atomic

  /// The positive and negative bounds of the class metadata.
  //  TargetMetadataBounds<Runtime> Bounds;
  var bounds: _MetadataBounds

  /// Attempt to read the cached immediate-members offset.
  ///
  /// \return value if the read was successful, or nil if the cache hasn't
  ///   been filled yet
  func tryGetImmediateMembersOffset() -> StoredPointerDifference? {
    let value = immediateMembersOffset
    guard value != 0 else {
      return nil
    }
    return value
  }

  func tryGet() -> _ClassMetadataBounds? {
    let offset = immediateMembersOffset
    guard offset != 0 else {
      return nil
    }
    return _ClassMetadataBounds(
      base: bounds,
      immediateMembersOffset: offset
    )
  }
}

struct _MetadataBounds {
  /// The negative extent of the metadata, in words.
  var negativeSizeInWords: UInt32

  /// The positive extent of the metadata, in words.
  var positiveSizeInWords: UInt32
}

struct _ClassMetadataBounds {
  var base: _MetadataBounds

  /// The offset from the address point of the metadata to the immediate
  /// members. In bytes
  typealias StoredPointerDifference = Int // ptrdiff_t
  var immediateMembersOffset: StoredPointerDifference
}
