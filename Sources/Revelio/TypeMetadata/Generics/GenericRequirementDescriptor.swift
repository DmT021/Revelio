// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

struct InvertibleProtocolSet {
  var bits: UInt16
}

struct _GenericRequirementDescriptor {
  struct InvertedProtocols {
    var genericParamIndex: UInt16
    var protocols: InvertibleProtocolSet
  }

  struct PayloadUnion {
    var data: UInt32

    /// A mangled representation of the same-type or base class the param is
    /// constrained to.
    ///
    /// Only valid if the requirement has SameType or BaseClass kind.
    var type: RelativeDirectPointer<Int32, CChar> {
      RelativeDirectPointer(relativeOffset: Int32(bitPattern: data))
    }

    /// The protocol the param is constrained to.
    ///
    /// Only valid if the requirement has Protocol kind.
    // RelativeTargetProtocolDescriptorPointer<Runtime> Protocol;
    typealias SignedContextPointer = UnsafeRawSignedPointer<PtrAuthKeys.ProcessIndependentData>
    typealias BoolInt = UInt8
    typealias RelativeContextPointerIntPair = RelativeIndirectablePointerIntPair<Int32, /*reserved=*/BoolInt, _ProtocolDescriptor>

    struct RelativeProtocolDescriptorPointer {
      var data: Int32

      var swiftPointer: RelativeContextPointerIntPair {
        RelativeContextPointerIntPair(relativeOffsetPlusIndirectAndInt: data)
      }

      #if canImport(ObjectiveC)
      var objcPointer: RelativeIndirectablePointerIntPair<Int32, BoolInt, Void> {
        RelativeIndirectablePointerIntPair(relativeOffsetPlusIndirectAndInt: data)
      }
      #endif

      var isObjC: Bool {
        #if canImport(ObjectiveC)
        objcPointer.int != 0
        #else
        false
        #endif
      }
    }

    var `protocol`: RelativeProtocolDescriptorPointer {
      RelativeProtocolDescriptorPointer(data: Int32(bitPattern: data))
    }

    /// The conformance the param is constrained to use.
    ///
    /// Only valid if the requirement has SameConformance kind.
    // RelativeIndirectablePointer<TargetProtocolConformanceDescriptor<Runtime>,
    //                            /*nullable*/ false> Conformance;
    typealias TargetProtocolConformanceDescriptor = ()
    var conformance: RelativeIndirectablePointer<Int32, TargetProtocolConformanceDescriptor> {
      RelativeIndirectablePointer(relativeOffsetPlusIndirect: Int32(bitPattern: data))
    }

    /// The kind of layout constraint.
    ///
    /// Only valid if the requirement has Layout kind.
    // GenericRequirementLayoutKind Layout;
    // var layout:

    /// The set of invertible protocols whose check is disabled, along
    /// with the index of the generic parameter to which this applies.
    ///
    /// The index is technically redundant with the subject type, but its
    /// storage is effectively free because this union is 32 bits anyway. The
    /// index 0xFFFF is reserved for "not a generic parameter", in which case
    /// the constraints are on the subject type.
    ///
    /// Only valid if the requirement has InvertedProtocols kind.
    var invertedProtocols: InvertedProtocols {
      let data = data
      return withUnsafePointer(to: data) { ptr in
        UnsafeRawPointer(ptr)
          .assumingMemoryBound(to: InvertedProtocols.self)
          .pointee
      }
    }
  }

  var flags: GenericRequirementFlags

  /// The type that's constrained, described as a mangled name.
  // RelativeDirectPointer<const char, /*nullable*/ false> Param;
  var param: RelativeDirectPointer<Int32, CChar>

  var payloadUnion: PayloadUnion
}
