// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

public protocol StructDescriptor: TypeContextDescriptor {
  var numFields: Int { get }
  var fieldOffsetVectorOffset: Int { get }
}

public struct StructDescriptorPointer: StructDescriptor {
  typealias Pointee = _StructDescriptor

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

  var genericParameterDescriptors: UnsafeBufferPointer<_GenericParamDescriptor>? {
    // it's immediatelly after genericContext
    guard let genericContext else {
      return nil
    }
    return UnsafeBufferPointer(
      start: genericContext.ptr.end
        .assumingMemoryBound(to: _GenericParamDescriptor.self),
      count: genericContext.numParams
    )
  }

  // StructDescriptor

  public var numFields: Int {
    Int(ptr.pointee.numFields)
  }

  public var fieldOffsetVectorOffset: Int {
    Int(ptr.pointee.fieldOffsetVectorOffset)
  }
}

extension StructDescriptorPointer: Hashable {}

/// include/swift/ABI/Metadata.h
///
// template <typename Runtime>
// class swift_ptrauth_struct_context_descriptor(StructDescriptor)
//    TargetStructDescriptor final
//    : public TargetValueTypeDescriptor<Runtime>,
//      public TrailingGenericContextObjects<TargetStructDescriptor<Runtime>,
//                            TargetTypeGenericContextDescriptorHeader,
//                            /*additional trailing objects*/
//                            TargetForeignMetadataInitialization<Runtime>,
//                            TargetSingletonMetadataInitialization<Runtime>,
//                            TargetCanonicalSpecializedMetadatasListCount<Runtime>,
//                            TargetCanonicalSpecializedMetadatasListEntry<Runtime>,
//                            TargetCanonicalSpecializedMetadatasCachingOnceToken<Runtime>,
//                            InvertibleProtocolSet,
//                            TargetSingletonMetadataPointer<Runtime>>
struct _StructDescriptor {
  var base: _TypeContextDescriptor

  /// The number of stored properties in the struct.
  /// If there is a field offset vector, this is its length.
  var numFields: UInt32

  /// The offset of the field offset vector for this struct's stored
  /// properties in its metadata, if any. 0 means there is no field offset
  /// vector.
  var fieldOffsetVectorOffset: UInt32
}
