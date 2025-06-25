// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

public protocol TypeContextDescriptor: ContextDescriptor {
  var name: String { get }
  var typeFlags: TypeContextDescriptorFlags { get }
}

public struct TypeContextDescriptorPointer: TypeContextDescriptor {
  typealias Pointee = _TypeContextDescriptor

  var ptr: UnsafePointer<Pointee>

  init(ptr: UnsafePointer<Pointee>) {
    self.ptr = ptr
  }

  init(rawPtr: UnsafeRawPointer) {
    self.init(ptr: rawPtr.assumingMemoryBound(to: Pointee.self))
  }

  var base: ContextDescriptorPointer {
    ContextDescriptorPointer(ptr: ptr.pointer(to: \.base)!)
  }

  public var flags: ContextDescriptorFlags { base.flags }

  public var parent: ContextDescriptorPointer? { base.parent }

  public var name: String {
    guard
      let namePtr = RelativeDirectPointer.resolve(from: ptr, keypath: \.name)
    else {
      return ""
    }
    return String(cString: namePtr)
  }

  public var typeFlags: TypeContextDescriptorFlags {
    TypeContextDescriptorFlags(value: flags.kindSpecificFlags)
  }
}

extension TypeContextDescriptorPointer: Hashable {}

/// include/swift/ABI/Metadata.h
///
// template <typename Runtime>
// class swift_ptrauth_struct_context_descriptor(TypeContextDescriptor)
//    TargetTypeContextDescriptor : public TargetContextDescriptor<Runtime>
struct _TypeContextDescriptor {
  var base: _ContextDescriptor

  /// The name of the type.
  // TargetRelativeDirectPointer<Runtime, const char, /*nullable*/ false> Name;
  var name: RelativeDirectPointer<Int32, CChar>

  /// A pointer to the metadata access function for this type.
  ///
  /// The function type here is a stand-in. You should use getAccessFunction()
  /// to wrap the function pointer in an accessor that uses the proper calling
  /// convention for a given number of arguments.
  //  TargetCompactFunctionPointer<Runtime, MetadataResponse(...),
  //                              /*Nullable*/ true> AccessFunctionPtr;
  var accessFunctionPtr: Int32 // TODO: add support

  typealias _FieldDescriptor = Void // TODO: add support
  var fields: RelativeDirectPointer<Int32, _FieldDescriptor>
}
