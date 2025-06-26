// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

extension TypeMetadata {
  public struct Class {
    public struct SwiftSpecific {
      typealias Pointee = _SwiftClassMetadata

      var ptr: UnsafePointer<Pointee>

      public var flags: ClassFlags {
        ptr.pointee.flags
      }

      public var instanceAddressPoint: Int {
        Int(ptr.pointee.instanceAddressPoint)
      }

      public var instanceSize: Int {
        Int(ptr.pointee.instanceSize)
      }

      public var instanceAlignMask: Int {
        Int(ptr.pointee.instanceAlignMask)
      }

      public var classSize: Int {
        Int(ptr.pointee.classSize)
      }

      /// The offset of the address point within the class object.
      // uint32_t ClassAddressPoint;
      public var classAddressPoint: Int {
        Int(ptr.pointee.classAddressPoint)
      }

      public var descriptor: ClassDescriptorPointer {
        ClassDescriptorPointer(
          rawPtr: ptr.pointee.descriptor.stripped
        )
      }

      public var genericArguments: [GenericArgument?]? {
        guard
          let genericParameterDescriptors = descriptor.genericParameterDescriptors
        else {
          return []
        }
        guard
          let genericArgumentOffset = descriptor.genericArgumentOffset
        else {
          return nil
        }
        return copyGenericArguments(
          metadataPtr: ptr,
          offsetInWords: Int(genericArgumentOffset),
          params: genericParameterDescriptors
        )
      }
    }

    typealias Pointee = _ClassMetadata

    var ptr: UnsafePointer<Pointee>

    init(ptr: UnsafePointer<Pointee>) {
      self.ptr = ptr
    }

    init(type: Any.Type) {
      self.init(ptr: unsafeBitCast(type, to: UnsafePointer<Pointee>.self))
    }

    public var type: Any.Type {
      unsafeBitCast(ptr, to: Any.Type.self)
    }

    // Ideally it should be a more strict type, but it can't be just
    // `TypeMetadata.Class` because it probably can also be `ObjCClassWrapper`
    public var superclass: Any.Type? {
      guard
        let superclassPtr = ptr.pointee.anyClassMetadata.superclass?.stripped
      else {
        return nil
      }
      return unsafeBitCast(superclassPtr, to: Any.Type.self)
    }

    public var swift: SwiftSpecific? {
      if ptr.pointee.isPureObjC {
        return nil
      }
      return SwiftSpecific(
        ptr: UnsafeRawPointer(ptr)
          .assumingMemoryBound(to: _SwiftClassMetadata.self)
      )
    }
  }
}

/// include/swift/ABI/Metadata.h

struct _AnyClassMetadata {
  /// The metadata for the superclass.  This is null for the root class.
  //  TargetSignedPointer<Runtime, const TargetClassMetadata *
  //                                   __ptrauth_swift_objc_superclass>
  //      Superclass;
  var superclass: UnsafeRawSignedPointer<PtrAuthKeys.ProcessIndependentData>?
}

/// This is the class metadata object for all classes (Swift and ObjC) in a
/// runtime that has Objective-C interoperability.
struct _AnyClassMetadataObjCInterop {
  /// The cache data is used for certain dynamic lookups; it is owned
  /// by the runtime and generally needs to interoperate with
  /// Objective-C's use.
  //  TargetPointer<Runtime, void> CacheData[2];
  var cacheData1: OpaquePointer
  var cacheData2: OpaquePointer

  /// The data pointer is used for out-of-line metadata and is
  /// generally opaque, except that the compiler sets the low bit in
  /// order to indicate that this is a Swift metatype and therefore
  /// that the type metadata header is present.
  // StoredSize Data;
  var data: Int // size_t

//  /// Is this object a valid swift type metadata?  That is, can it be
//  /// safely downcast to ClassMetadata?
//  var isTypeMetadata: Bool {
//    data & SWIFT_CLASS_IS_SWIFT_MASK
//  }
//  bool isPureObjC() const {
//    return !isTypeMetadata();
//  }
  var isPureObjC: Bool {
    #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
    let swiftClassIsSwiftMask = 2
    #elseif os(Windows) || os(Linux)
    let swiftClassIsSwiftMask = 1
    #else
    #error("Unknown platform")
    #endif
    let isTypeMetadata = data & swiftClassIsSwiftMask != 0
    return !isTypeMetadata
  }
}

struct _ClassMetadata {
  // From TargetMetadata
  var kind: Int

  var anyClassMetadata: _AnyClassMetadata

  #if canImport(ObjectiveC)
  // only if the runtime supports obj-c interop
  var anyClassMetadataObjCInterop: _AnyClassMetadataObjCInterop
  var isPureObjC: Bool { anyClassMetadataObjCInterop.isPureObjC }
  #else
  var isPureObjC: Bool { false }
  #endif
}

struct _SwiftClassMetadata {
  var _ClassMetadata: _ClassMetadata

  // The remaining fields are valid only when isTypeMetadata().
  // The Objective-C runtime knows the offsets to some of these fields.
  // Be careful when accessing them.

  /// Swift-specific class flags.
  //  ClassFlags Flags;
  var flags: ClassFlags

  /// The address point of instances of this type.
  //  uint32_t InstanceAddressPoint;
  var instanceAddressPoint: UInt32

  /// The required size of instances of this type.
  /// 'InstanceAddressPoint' bytes go before the address point;
  /// 'InstanceSize - InstanceAddressPoint' bytes go after it.
  // uint32_t InstanceSize;
  var instanceSize: UInt32

  /// The alignment mask of the address point of instances of this type.
  // uint16_t InstanceAlignMask;
  var instanceAlignMask: UInt16

  /// Reserved for runtime use.
  // uint16_t Reserved;
  var reserved: UInt16

  /// The total size of the class object, including prefix and suffix
  /// extents.
  // uint32_t ClassSize;
  var classSize: UInt32

  /// The offset of the address point within the class object.
  // uint32_t ClassAddressPoint;
  var classAddressPoint: UInt32

  /// An out-of-line Swift-specific description of the type, or null
  /// if this is an artificial subclass.  We currently provide no
  /// supported mechanism for making a non-artificial subclass
  /// dynamically.
  //  TargetSignedPointer<Runtime, const TargetClassDescriptor<Runtime> *
  //  __ptrauth_swift_type_descriptor> Description;
  var descriptor: UnsafeRawSignedPointer<PtrAuthKeys.ProcessIndependentData>

  /// A function for destroying instance variables, used to clean up after an
  /// early return from a constructor. If null, no clean up will be performed
  /// and all ivars must be trivial.
  //  TargetSignedPointer<Runtime, ClassIVarDestroyer * __ptrauth_swift_heap_object_destructor>
  //  IVarDestroyer;
  var ivarDestroyer: OpaquePointer
}

struct _HeapMetadataHeader {
  var _TypeMetadataLayoutPrefix: _TypeMetadataLayoutPrefix
  var _HeapMetadataHeaderPrefix: _HeapMetadataHeaderPrefix
  var _TypeMetadataHeaderBase: _TypeMetadataHeaderBase
}

struct _TypeMetadataLayoutPrefix {
  //  TargetSignedPointer<Runtime, const uint8_t *
  //                                    __ptrauth_swift_type_layout_string>
  //      layoutString;
  var layoutPrefix: UnsafeRawSignedPointer<PtrAuthKeys.ProcessIndependentData>
}

struct _HeapMetadataHeaderPrefix {
  /// Destroy the object, returning the allocated size of the object
  /// or 0 if the object shouldn't be deallocated.
  //  TargetSignedPointer<Runtime, HeapObjectDestroyer *
  //                                   __ptrauth_swift_heap_object_destructor>
  //      destroy;
  var destroy: OpaquePointer
}

struct _TypeMetadataHeaderBase {
  /// A pointer to the value-witnesses for this type.  This is only
  /// present for type metadata.
  //  TargetPointer<Runtime, const TargetValueWitnessTable<Runtime>> ValueWitnesses;
  var valueWitness: UnsafeRawPointer
}
