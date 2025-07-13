// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

public protocol ProtocolDescriptor: ContextDescriptor {
  var numRequirements: Int { get }
  var numRequirementsInSignature: Int { get }
  var name: String? { get }
  var associatedTypeNames: String? { get }
}

public struct ProtocolDescriptorPointer: ProtocolDescriptor {
  typealias Pointee = _ProtocolDescriptor

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

  // ContextDescriptor

  public var flags: ContextDescriptorFlags { base.flags }

  public var parent: ContextDescriptorPointer? { base.parent }

  // ProtocolDescriptor

  public var numRequirements: Int {
    Int(ptr.pointee.numRequirements)
  }

  public var numRequirementsInSignature: Int {
    Int(ptr.pointee.numRequirementsInSignature)
  }

  public var name: String? {
    RelativeDirectPointer
      .resolve(from: ptr, keypath: \.name)
      .map {
        String(cString: $0)
      }
  }

  public var associatedTypeNames: String? {
    RelativeDirectPointer
      .resolve(from: ptr, keypath: \.associatedTypeNames)
      .map {
        String(cString: $0)
      }
  }
}

extension ProtocolDescriptorPointer: Hashable {}

struct _ProtocolDescriptor {
  var base: _ContextDescriptor

  /// The name of the protocol.
  // TargetRelativeDirectPointer<Runtime, const char, /*nullable*/ false> Name;
  var name: RelativeDirectPointer<Int32, CChar>

  /// The number of generic requirements in the requirement signature of the
  /// protocol.
  var numRequirementsInSignature: UInt32

  /// The number of requirements in the protocol.
  /// If any requirements beyond MinimumWitnessTableSizeInWords are present
  /// in the witness table template, they will be not be overwritten with
  /// defaults.
  var numRequirements: UInt32

  /// Associated type names, as a space-separated list in the same order
  /// as the requirements.
  // RelativeDirectPointer<const char, /*Nullable=*/true> AssociatedTypeNames;
  var associatedTypeNames: RelativeDirectPointer<Int32, CChar>
}
