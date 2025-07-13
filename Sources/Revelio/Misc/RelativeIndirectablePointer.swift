// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

// include/swift/Basic/RelativePointer.h
public struct RelativeIndirectablePointer<Offset, Pointee> where Offset: BinaryInteger,
  Offset: SignedInteger
{
  public var relativeOffsetPlusIndirect: Offset

  public var isNull: Bool {
    relativeOffsetPlusIndirect == 0
  }

  public func pointer(from ptr: UnsafeRawPointer) -> UnsafePointer<Pointee>? {
    if isNull {
      return nil
    }

    // If the low bit is set, then this is an indirect address. Otherwise,
    // it's direct.
    let isIndirect = (relativeOffsetPlusIndirect & 1) != 0

    let offset = relativeOffsetPlusIndirect & ~1 // clear the low bit
    let address = ptr.advanced(by: Int(offset))

    if isIndirect {
      return address.load(as: UnsafePointer<Pointee>.self)
    }
    return address.assumingMemoryBound(to: Pointee.self)
  }

  public func pointee(from ptr: UnsafeRawPointer) -> Pointee? {
    pointer(from: ptr)?.pointee
  }
}

public struct RelativeIndirectablePointerIntPair<Offset, IntTy, Pointee>
  where
  Offset: BinaryInteger,
  Offset: SignedInteger,
  IntTy: BinaryInteger
{
  public var relativeOffsetPlusIndirectAndInt: Offset

  var mask: Offset {
    (Offset(MemoryLayout<Offset>.alignment) - 1) & ~1
  }

  var unresolvedOffset: Offset {
    relativeOffsetPlusIndirectAndInt & ~mask
  }

  public var isNull: Bool {
    unresolvedOffset == 0
  }

  public var int: IntTy {
    IntTy((relativeOffsetPlusIndirectAndInt & mask) >> 1)
  }

  public func pointer(from ptr: UnsafeRawPointer) -> UnsafePointer<Pointee>? {
    let unresolvedOffset = unresolvedOffset

    if isNull {
      return nil
    }

    let offsetPlusIndirect = unresolvedOffset
    // If the low bit is set, then this is an indirect address. Otherwise,
    // it's direct.
    let isIndirect = (offsetPlusIndirect & 1) != 0

    let offset = offsetPlusIndirect & ~1 // clear the low bit
    let address = ptr.advanced(by: Int(offset))

    if isIndirect {
      return address.load(as: UnsafePointer<Pointee>.self)
    }
    return address.assumingMemoryBound(to: Pointee.self)
  }
}

public struct RelativeDirectPointerIntPair<Offset, IntTy, Pointee>
  where
  Offset: BinaryInteger,
  Offset: SignedInteger,
  IntTy: BinaryInteger
{
  public var relativeOffsetPlusInt: Offset

  var mask: Offset {
    Offset(MemoryLayout<Offset>.alignment) - 1
  }

  var offset: Offset {
    relativeOffsetPlusInt & ~mask
  }

  public var isNull: Bool {
    offset == 0
  }

  public var int: IntTy {
    IntTy(relativeOffsetPlusInt & mask)
  }

  public func pointer(from ptr: UnsafeRawPointer) -> UnsafePointer<Pointee>? {
    let offset = offset

    if isNull {
      return nil
    }

    let address = ptr.advanced(by: Int(offset))

    return address.assumingMemoryBound(to: Pointee.self)
  }
}
