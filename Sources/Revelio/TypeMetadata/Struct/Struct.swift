// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

extension TypeMetadata {
  public struct Struct {
    var ptr: UnsafePointer<_StructMetadata>

    init(type: Any.Type) {
      ptr = unsafeBitCast(type, to: UnsafePointer<_StructMetadata>.self)
    }

    public var descriptor: StructDescriptorPointer {
      StructDescriptorPointer(rawPtr: ptr.pointee.descriptor.stripped)
    }

    public var genericParameters: [Any.Type] {
      guard let genericContext = descriptor.genericContext else {
        return []
      }
      let numParams = genericContext.numParams
      return Array(unsafeUninitializedCapacity: numParams) { buffer, initializedCount in
        initializedCount = numParams
        let genericParametersStart = UnsafeRawPointer(ptr)
          .advanced(by: MemoryLayout<_StructMetadata>.size)
        let genericParameters = UnsafeBufferPointer(
          start: genericParametersStart.assumingMemoryBound(to: Any.Type.self),
          count: numParams
        )
        for i in 0..<numParams {
          buffer.initializeElement(
            at: i,
            to: genericParameters[i]
          )
        }
      }
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
