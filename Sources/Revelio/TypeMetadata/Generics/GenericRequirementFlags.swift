// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

public enum GenericRequirementKind {
  /// A protocol requirement.
  case `protocol`
  /// A same-type requirement.
  case sameType
  /// A base class requirement.
  case baseClass
  /// A "same-conformance" requirement, implied by a same-type or base-class
  /// constraint that binds a parameter with protocol requirements.
  case sameConformance
  /// A same-shape requirement between generic parameter packs.
  case sameShape
  /// A requirement stating which invertible protocol checks are
  /// inverted.
  ///
  /// This is more of an "anti-requirement", specifing which checks don't need
  /// to happen for a given type.
  case invertedProtocols
  /// A layout requirement.
  case layout

  init?(rawValue: UInt8) {
    switch rawValue {
    case 0: self = .protocol
    case 1: self = .sameType
    case 2: self = .baseClass
    case 3: self = .sameConformance
    case 4: self = .sameShape
    case 5: self = .invertedProtocols
    case 0x1F: self = .layout
    default: return nil
    }
  }
}

public struct GenericRequirementFlags: CustomDebugStringConvertible {
  var value: UInt32

  /// If this is true, the subject type of the requirement is a pack.
  /// When the requirement is a conformance requirement, the corresponding
  /// entry in the generic arguments array becomes a TargetWitnessTablePack.
  public var isPackRequirement: Bool {
    value & 0x20 != 0
  }

  public var hasKeyArgument: Bool {
    value & 0x80 != 0
  }

  /// If this is true, the subject type of the requirement is a value.
  ///
  /// Note: We could introduce a new SameValue requirement instead of burning a
  /// a bit for value requirements, but if somehow an existing requirement makes
  /// sense for values besides "SameType" then this would've been better.
  public var isValueRequirement: Bool {
    value & 0x100 != 0
  }

  public var kind: GenericRequirementKind? {
    GenericRequirementKind(rawValue: UInt8(value & 0x1F))
  }

  public var debugDescription: String {
    var s = ""
    if let kind {
      s += "\(kind)"
    } else {
      s += "unknown_kind"
    }
    if isPackRequirement {
      s += " isPackRequirement"
    }
    if hasKeyArgument {
      s += " hasKeyArgument"
    }
    if isValueRequirement {
      s += " isValueRequirement"
    }
    return s
  }
}
