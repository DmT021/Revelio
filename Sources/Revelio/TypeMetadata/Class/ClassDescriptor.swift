// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

#if canImport(ObjectiveC)
import ObjectiveC
#endif

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

  public var resilientSuperclass: OpaquePointer? {
    guard typeFlags.classHasResilientSuperclass else {
      return nil
    }

    var offset = 0

    if let genericContext {
      offset += genericContext.totalSize
    }

    let resilientSuperclassObjectPtr = (ptr.end.advanced(by: offset))
      .assumingMemoryBound(to: _ResilientSuperclass.self)

    return RelativeDirectPointer
      .resolve(
        from: resilientSuperclassObjectPtr,
        keypath: \.superclass
      )
      .map {
        OpaquePointer($0)
      }
  }

  /// Return the offset of the start of generic arguments in the nominal
  /// type's metadata. The returned value is measured in words.
  var genericArgumentOffset: Int32? {
    if typeFlags.classHasResilientSuperclass {
      var resilientImmediateMembersOffset: Int32? {
        // assert(description->hasResilientSuperclass());
        let resilientMetadataBoundsPtr = ptr.pointee
          .metadataNegativeSizeInWordsOrResilientMetadataBounds
          .resilientMetadataBounds
          .pointer(from: ptr.pointer(to: \.metadataNegativeSizeInWordsOrResilientMetadataBounds)!)!

        // try get the cached value
        if let immediateMembersOffset
            = resilientMetadataBoundsPtr.pointee.tryGetImmediateMembersOffset() {
          return Int32(immediateMembersOffset / MemoryLayout<UnsafeRawPointer>.size)
        }

        guard
          let bounds = metadataBounds
        else {
          assertionFailure("Can get metadata bounds")
          return nil
        }
        return Int32(bounds.immediateMembersOffset / MemoryLayout<UnsafeRawPointer>.size)
      }
      return resilientImmediateMembersOffset
    } else {
      guard
        let bounds = metadataBounds
      else {
        return nil
      }
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
    if let resilientSuperclass {
      assert(typeFlags.classHasResilientSuperclass)
      guard
        let resilientSuperclassReferenceKind = typeFlags.classResilientSuperclassReferenceKind
      else {
        assertionFailure("Unknown classResilientSuperclassReferenceKind")
        return nil
      }

      let resilientMetadataBoundsPtr = ptr.pointee
        .metadataNegativeSizeInWordsOrResilientMetadataBounds
        .resilientMetadataBounds
        .pointer(from: ptr.pointer(to: \.metadataNegativeSizeInWordsOrResilientMetadataBounds)!)!

      guard
        let bounds = computeMetadataBoundsFromResilientSuperclass(
          resilientSuperclass: resilientSuperclass,
          refKind: resilientSuperclassReferenceKind,
          areImmediateMembersNegative: typeFlags.classAreImmediateMembersNegative,
          numImmediateMembers: ptr.pointee.numImmediateMembers,
          storedBounds: resilientMetadataBoundsPtr
        )
      else {
        assertionFailure("Can get metadata bounds")
        return nil
      }
      return bounds
    } else {
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
}

extension ClassDescriptorPointer: Hashable {}

// From stdlib/public/runtime/Metadata.cpp
// static ClassMetadataBounds computeMetadataBoundsFromSuperclass(
//                                      const ClassDescriptor *description,
//                                      StoredClassMetadataBounds &storedBounds)
private func computeMetadataBoundsFromResilientSuperclass(
  resilientSuperclass superRef: OpaquePointer,
  refKind: TypeReferenceKind,
  areImmediateMembersNegative: Bool,
  numImmediateMembers: UInt32,
  storedBounds: UnsafePointer<_StoredClassMetadataBounds>
) -> _ClassMetadataBounds? {
  // Compute the bounds for the superclass, extending it to the minimum
  // bounds of a Swift class.
  guard
    var bounds: _ClassMetadataBounds = computeMetadataBoundsForSuperclass(
      resilientSuperclass: superRef,
      refKind: refKind
    )
  else {
    return nil
  }
  bounds.adjustForSubclass(
    areImmediateMembersNegative: areImmediateMembersNegative,
    numImmediateMembers: numImmediateMembers
  )
  return bounds
}

// static ClassMetadataBounds
// computeMetadataBoundsForSuperclass(const void *ref,
//                                   TypeReferenceKind refKind) {
private func computeMetadataBoundsForSuperclass(
  resilientSuperclass ref: OpaquePointer,
  refKind: TypeReferenceKind,
) -> _ClassMetadataBounds? {
  switch refKind {
  case .indirectTypeDescriptor:
    typealias TypeDescriptorSignedPointer =
      UnsafeRawSignedPointer<PtrAuthKeys.ProcessIndependentData>
    guard
      let ptr = UnsafePointer<TypeDescriptorSignedPointer?>(ref)
        .pointee?
        .stripped
    else {
      // swift::fatalError(0, "instantiating class metadata for class with "
      //                     "missing weak-linked ancestor");
      assertionFailure()
      return nil
    }
    let descriptor = ClassDescriptorPointer(rawPtr: ptr)
    return descriptor.metadataBounds

  case .directTypeDescriptor:
    let descriptor = ClassDescriptorPointer(rawPtr: UnsafeRawPointer(ref))
    return descriptor.metadataBounds

  case .directObjCClassName:
    #if canImport(ObjectiveC)
    let name = UnsafePointer<CChar>(ref)
    guard
      let cls = objc_lookUpClass(name)
    else {
      let name = String(validatingCString: name) ?? "can't get name"
      assertionFailure("objc_lookUpClass failed for \"\(name)\"")
      return nil
    }
    return computeMetadataBoundsForObjCClass(cls)
    #else
    break
    #endif

  case .indirectObjCClass:
    #if canImport(ObjectiveC)
    guard
      let cls = UnsafePointer<AnyClass?>(ref).pointee
    else {
      assertionFailure()
      return nil
    }
    return computeMetadataBoundsForObjCClass(cls)
    #else
    break
    #endif
  }
}

#if canImport(ObjectiveC)
private func computeMetadataBoundsForObjCClass(_ cls: AnyClass) -> _ClassMetadataBounds? {
  let cls: AnyClass = revelio_getInitializedObjCClass(cls)
  return getClassBoundsAsSwiftSuperclass(cls: cls)
}
#endif

/// Given that this class is serving as the superclass of a Swift class,
/// return its bounds as metadata.
///
/// Note that the ImmediateMembersOffset member will not be meaningful.
private func getClassBoundsAsSwiftSuperclass(
  cls: AnyClass
) -> _ClassMetadataBounds? {
  guard
    let classMetadata = switch TypeMetadata(type: cls) {
    case let .class(meta): meta
    case let .objcClassWrapper(meta): meta.class
    default: nil
    }
  else {
    assertionFailure("Unhandled metadata kind for AnyClass")
    return nil
  }
  let rootBounds = _ClassMetadataBounds.forSwiftRootClass
  if let swiftSpecific = classMetadata.swift {
    var bounds = _ClassMetadataBounds.forAddressPointAndSize(
      addressPoint: swiftSpecific.classAddressPoint,
      totalSize: swiftSpecific.classSize
    )
    if bounds.base.negativeSizeInWords < rootBounds.base.negativeSizeInWords {
      bounds.base.negativeSizeInWords = rootBounds.base.negativeSizeInWords
    }
    if bounds.base.positiveSizeInWords < rootBounds.base.positiveSizeInWords {
      bounds.base.positiveSizeInWords = rootBounds.base.positiveSizeInWords
    }
    return bounds
  } else {
    return rootBounds
  }
}

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

  /// Return the basic bounds of all Swift class metadata.
  /// The immediate members offset will not be meaningful.
  fileprivate static var forSwiftRootClass: Self {
    let headerSize = MemoryLayout<_HeapMetadataHeader>.size
    let totalSize = headerSize + MemoryLayout<_ClassMetadata>.size
    return forAddressPointAndSize(
      addressPoint: headerSize,
      totalSize: totalSize
    )
  }

  /// Return the bounds of a Swift class metadata with the given address
  /// point and size (both in bytes).
  /// The immediate members offset will not be meaningful.
  fileprivate static func forAddressPointAndSize(
    addressPoint: Int, // size_t
    totalSize: Int // size_t
  ) -> Self {
    Self(
      base: _MetadataBounds(
        negativeSizeInWords: UInt32(addressPoint / MemoryLayout<UnsafeRawPointer>.size),
        positiveSizeInWords: UInt32((totalSize - addressPoint) / MemoryLayout<UnsafeRawPointer>
          .size)
      ),
      immediateMembersOffset: totalSize - addressPoint
    )
  }

  fileprivate mutating func adjustForSubclass(
    areImmediateMembersNegative: Bool,
    numImmediateMembers: UInt32
  ) {
    if areImmediateMembersNegative {
      base.negativeSizeInWords += numImmediateMembers
      immediateMembersOffset = -StoredPointerDifference(base.negativeSizeInWords) *
        MemoryLayout<UnsafeRawPointer>.size
    } else {
      immediateMembersOffset = Int(base.positiveSizeInWords) * MemoryLayout<UnsafeRawPointer>.size
      base.positiveSizeInWords += numImmediateMembers
    }
  }
}

// Trailing object for _ClassDescriptor
struct _ResilientSuperclass {
  var superclass: RelativeDirectPointer<Int32, Void>
}

extension UnsafePointer {
  /// Address next to the end of the current pointee
  fileprivate var end: UnsafeRawPointer {
    UnsafeRawPointer(self) + MemoryLayout<Pointee>.size
  }
}
