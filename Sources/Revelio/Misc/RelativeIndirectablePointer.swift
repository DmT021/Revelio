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
