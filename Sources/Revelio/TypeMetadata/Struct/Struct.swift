// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

extension Metadata {
  public struct Struct {
    var ptr: UnsafePointer<_StructMetadata>

    init(type: Any.Type) {
      ptr = unsafeBitCast(type, to: UnsafePointer<_StructMetadata>.self)
    }

    public var descriptor: StructDescriptorPointer {
      StructDescriptorPointer(rawPtr: ptr.pointee.descriptor.stripped)
    }

    public var genericArguments: [GenericArgument?] {
      guard
        let genericParameterDescriptors = descriptor.genericParameterDescriptors
      else {
        return []
      }
      let offsetInWords = MemoryLayout<_StructMetadata>.size / MemoryLayout<UnsafeRawPointer>.size
      return copyGenericArguments(
        metadataPtr: ptr,
        offsetInWords: offsetInWords,
        params: genericParameterDescriptors
      )
    }
  }
}

/// include/swift/ABI/Metadata.h
struct _StructMetadata {
  // From TargetMetadata
  var kind: Int

  // a signed pointer to `StructDescriptor`
  //
  // From TargetValueMetadata:
  // TargetSignedPointer<Runtime, const TargetValueTypeDescriptor<Runtime> *
  // __ptrauth_swift_type_descriptor> Description;
  // #define __ptrauth_swift_type_descriptor \
  //  __ptrauth(ptrauth_key_process_independent_data, 1, \
  //            SpecialPointerAuthDiscriminators::TypeDescriptor)
  var descriptor: UnsafeRawSignedPointer<PtrAuthKeys
    .ProcessIndependentData>
}
