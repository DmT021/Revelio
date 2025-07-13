// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

public protocol EnumDescriptor: TypeContextDescriptor {}

public struct EnumDescriptorPointer: EnumDescriptor {
  typealias Pointee = _EnumDescriptor

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

  public var fieldsDescriptor: FieldDescriptorPointer? {
    base.fieldsDescriptor
  }

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

  var genericRequirementDescriptors: UnsafeBufferPointer<_GenericRequirementDescriptor>? {
    guard
      let genericContext,
      let base = genericParameterDescriptors?.endAligned4
    else {
      return nil
    }
    return UnsafeBufferPointer(
      start: base
        .assumingMemoryBound(to: _GenericRequirementDescriptor.self),
      count: genericContext.numRequirements
    )
  }

  // EnumDescriptor

  public var numPayloadCases: Int {
    Int(ptr.pointee.numPayloadCasesAndPayloadSizeOffset & 0x00FF_FFFF)
  }

  var payloadSizeOffset: Int? {
    let offset = (ptr.pointee.numPayloadCasesAndPayloadSizeOffset >> 24) & 0xFF
    if offset == 0 {
      return nil
    }
    return Int(offset)
  }

  public var numEmptyCases: Int {
    Int(ptr.pointee.numEmptyCases)
  }
}

extension EnumDescriptorPointer: Hashable {}

/// include/swift/ABI/Metadata.h
///
// template <typename Runtime>
// class swift_ptrauth_struct_context_descriptor(EnumDescriptor)
//    TargetEnumDescriptor final
//    : public TargetValueTypeDescriptor<Runtime>,
//      public TrailingGenericContextObjects<TargetEnumDescriptor<Runtime>,
//                            TargetTypeGenericContextDescriptorHeader,
//                            /*additional trailing objects*/
//                            TargetForeignMetadataInitialization<Runtime>,
//                            TargetSingletonMetadataInitialization<Runtime>,
//                            TargetCanonicalSpecializedMetadatasListCount<Runtime>,
//                            TargetCanonicalSpecializedMetadatasListEntry<Runtime>,
//                            TargetCanonicalSpecializedMetadatasCachingOnceToken<Runtime>,
//                            InvertibleProtocolSet,
//                            TargetSingletonMetadataPointer<Runtime>>
struct _EnumDescriptor {
  var base: _TypeContextDescriptor

  /// The number of non-empty cases in the enum are in the low 24 bits;
  /// the offset of the payload size in the metadata record in words,
  /// if any, is stored in the high 8 bits.
  var numPayloadCasesAndPayloadSizeOffset: UInt32

  /// The number of empty cases in the enum.
  var numEmptyCases: UInt32
}
