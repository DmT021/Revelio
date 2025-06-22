// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

public protocol GenericContextDescriptorHeader {
  var numParams: Int { get }
  var numRequirements: Int { get }
  var numKeyArguments: Int { get }
  var flags: GenericContextDescriptorFlags { get }
}

public struct GenericContextDescriptorHeaderPointer: GenericContextDescriptorHeader {
  typealias Pointee = _GenericContextDescriptorHeader

  var ptr: UnsafePointer<Pointee>

  init(ptr: UnsafePointer<Pointee>) {
    self.ptr = ptr
  }

  init(rawPtr: UnsafeRawPointer) {
    self.init(ptr: rawPtr.assumingMemoryBound(to: Pointee.self))
  }

  public var numParams: Int {
    Int(ptr.pointee.numParams)
  }

  public var numRequirements: Int {
    Int(ptr.pointee.numRequirements)
  }

  public var numKeyArguments: Int {
    Int(ptr.pointee.numKeyArguments)
  }

  public var flags: GenericContextDescriptorFlags {
    ptr.pointee.flags
  }
}

/// include/swift/ABI/GenericContext.h
struct _GenericContextDescriptorHeader {
  /// The number of (source-written) generic parameters, and thus
  /// the number of GenericParamDescriptors associated with this
  /// context.  The parameter descriptors appear in the order in
  /// which they were given in the source.
  ///
  /// A GenericParamDescriptor corresponds to a type metadata pointer
  /// in the arguments layout when isKeyArgument() is true.
  /// isKeyArgument() will be false if the parameter has been made
  /// equivalent to a different parameter or a concrete type.
  var numParams: UInt16

  /// The number of GenericRequirementDescriptors in this generic
  /// signature.
  ///
  /// A GenericRequirementDescriptor of kind Protocol corresponds
  /// to a witness table pointer in the arguments layout when
  /// isKeyArgument() is true.  isKeyArgument() will be false if
  /// the protocol is an Objective-C protocol.  (Unlike generic
  /// parameters, redundant conformance requirements can simply be
  /// eliminated, and so that case is not impossible.)
  var numRequirements: UInt16

  /// The size of the "key" area of the argument layout, in words.
  /// Key arguments include shape classes, generic parameters and
  /// conformance requirements which are part of the identity of
  /// the context.
  ///
  /// The key area of the argument layout consists of:
  ///
  /// - a sequence of pack lengths, in the same order as the parameter
  ///   descriptors which satisfy getKind() == GenericParamKind::TypePack
  ///   and hasKeyArgument();
  ///
  /// - a sequence of metadata or metadata pack pointers, in the same
  ///   order as the parameter descriptors which satisfy hasKeyArgument();
  ///
  /// - a sequence of witness table or witness table pack pointers, in the
  ///   same order as the requirement descriptors which satisfy
  ///   hasKeyArgument().
  ///
  ///   a sequence of values, in the same order as the parameter descriptors
  ///   which satisify getKind() == GenericParamKind::Value and
  ///   hasKeyArgument();
  ///
  /// The elements above which are packs are precisely those appearing
  /// in the sequence of trailing GenericPackShapeDescriptors.
  var numKeyArguments: UInt16

  /// Originally this was the size of the "extra" area of the argument
  /// layout, in words.  The idea was that extra arguments would
  /// include generic parameters and conformances that are not part
  /// of the identity of the context; however, it's unclear why we
  /// would ever want such a thing.  As a result, in pre-5.8 runtimes
  /// this field is always zero.  New flags can only be added as long
  /// as they remains zero in code which must be compatible with
  /// older Swift runtimes.
  var flags: GenericContextDescriptorFlags
}
