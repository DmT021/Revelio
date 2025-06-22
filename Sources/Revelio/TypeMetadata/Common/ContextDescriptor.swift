// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

public protocol ContextDescriptor {
  var flags: ContextDescriptorFlags { get }
  var parent: ContextDescriptorPointer? { get }
}

public struct ContextDescriptorPointer: ContextDescriptor {
  typealias Pointee = _ContextDescriptor

  var ptr: UnsafePointer<Pointee>

  init(ptr: UnsafePointer<Pointee>) {
    self.ptr = ptr
  }

  init(rawPtr: UnsafeRawPointer) {
    self.init(ptr: rawPtr.assumingMemoryBound(to: Pointee.self))
  }

  public var flags: ContextDescriptorFlags {
    ptr.pointee.flags
  }

  public var parent: ContextDescriptorPointer? {
    guard
      let parentPtr = ptr.pointee.parent.pointer(from: ptr.pointer(to: \.parent)!)
    else {
      return nil
    }
    return ContextDescriptorPointer(ptr: parentPtr)
  }
}

extension ContextDescriptorPointer: Hashable {}

/// Base class for all context descriptors.
///
/// include/swift/ABI/Metadata.h
// template <typename Runtime>
// struct swift_ptrauth_struct_context_descriptor(ContextDescriptor)
//    TargetContextDescriptor
struct _ContextDescriptor {
  /// Flags describing the context, including its kind and format version.
  var flags: ContextDescriptorFlags // ContextDescriptorFlags Flags;

  /// The parent context, or null if this is a top-level context.
  /// `TargetRelativeContextPointer<Runtime> Parent;`
  typealias RelativeContextPointer = RelativeIndirectablePointer<Int32, _ContextDescriptor>
  var parent: RelativeContextPointer
}
