// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

extension Metadata {
  public struct Enum {
    typealias Pointee = _EnumMetadata

    var ptr: UnsafePointer<Pointee>

    init(type: Any.Type) {
      ptr = unsafeBitCast(type, to: UnsafePointer<Pointee>.self)
    }

    public var descriptor: EnumDescriptorPointer {
      EnumDescriptorPointer(rawPtr: ptr.pointee.descriptor.stripped)
    }

    public var genericArguments: [GenericArgument?] {
      guard
        let genericParameterDescriptors = descriptor.genericParameterDescriptors
      else {
        return []
      }
      let offsetInWords = MemoryLayout<_EnumMetadata>.size / MemoryLayout<UnsafeRawPointer>.size
      return copyGenericArguments(
        metadataPtr: ptr,
        offsetInWords: offsetInWords,
        params: genericParameterDescriptors
      )
    }

    /// Retrieve the size of the payload area.
    public var payloadSize: Int? {
      guard let offset = descriptor.payloadSizeOffset else {
        return nil
      }
      let asWords = UnsafeRawPointer(ptr).assumingMemoryBound(to: Int.self)
      return (asWords + offset).pointee
    }
  }
}

/// include/swift/ABI/Metadata.h
struct _EnumMetadata {
  // From TargetMetadata
  var kind: Int

  var descriptor: UnsafeRawSignedPointer<
    PtrAuthKeys
      .ProcessIndependentData
  >
}
