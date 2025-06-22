// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

public protocol TypeGenericContextDescriptorHeader: GenericContextDescriptorHeader {}

public struct TypeGenericContextDescriptorHeaderPointer: TypeGenericContextDescriptorHeader {
  typealias Pointee = _TypeGenericContextDescriptorHeader

  var ptr: UnsafePointer<Pointee>

  init(ptr: UnsafePointer<Pointee>) {
    self.ptr = ptr
  }

  init(rawPtr: UnsafeRawPointer) {
    self.init(ptr: rawPtr.assumingMemoryBound(to: Pointee.self))
  }

  var base: GenericContextDescriptorHeaderPointer {
    GenericContextDescriptorHeaderPointer(rawPtr: UnsafeRawPointer(ptr.pointer(to: \.base)!))
  }

  public var numParams: Int { base.numParams }

  public var numRequirements: Int { base.numRequirements }

  public var numKeyArguments: Int { base.numKeyArguments }

  public var flags: GenericContextDescriptorFlags { base.flags }
}

/// include/swift/ABI/Metadata.h
///
struct _TypeGenericContextDescriptorHeader {
  typealias GenericMetadataInstantiationCache = () // TODO: add support
  /// The metadata instantiation cache.
  //  TargetRelativeDirectPointer<Runtime,
  //                              TargetGenericMetadataInstantiationCache<Runtime>>
  //    InstantiationCache;
  var instantiationCache: RelativeDirectPointer<Int32, GenericMetadataInstantiationCache>

  typealias GenericMetadataPattern = ()
  /// The default instantiation pattern.
  //  TargetRelativeDirectPointer<Runtime, TargetGenericMetadataPattern<Runtime>>
  //    DefaultInstantiationPattern;
  var defaultInstantiationPattern: RelativeDirectPointer<Int32, GenericMetadataInstantiationCache>

  /// The base header.  Must always be the final member.
  //  TargetGenericContextDescriptorHeader<Runtime> Base;
  var base: _GenericContextDescriptorHeader
}
