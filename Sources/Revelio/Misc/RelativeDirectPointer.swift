// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

public struct RelativeDirectPointer<Offset, Pointee>
  where Offset: BinaryInteger, Offset: SignedInteger
{
  public var relativeOffset: Offset

  public var isNull: Bool {
    relativeOffset == 0
  }

  public func pointer(from ptr: UnsafeRawPointer) -> UnsafePointer<Pointee>? {
    if isNull {
      return nil
    }
    return ptr.advanced(by: Int(relativeOffset))
      .assumingMemoryBound(to: Pointee.self)
  }

  public func pointee(from ptr: UnsafeRawPointer) -> Pointee? {
    pointer(from: ptr)?.pointee
  }

  public static func resolve<T>(from ptr: UnsafePointer<T>,
                                keypath: KeyPath<T, Self>) -> UnsafePointer<Pointee>?
  {
    guard let propertyAddress = ptr.pointer(to: keypath) else {
      return nil
    }
    return ptr.pointee[keyPath: keypath].pointer(from: propertyAddress)
  }
}
