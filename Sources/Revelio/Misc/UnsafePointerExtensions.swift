// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

func alignUp4(_ v: UInt) -> UInt {
  (v + 3) & ~3
}

// Align by rounding up to the nearest multiple of 4
func alignedSize4(elementSize: Int, count: Int) -> Int {
  // size = (size + alignment-1) & ~(alignment-1);
  let totalSize = elementSize * count
  return Int(alignUp4(UInt(totalSize)))
}

extension UnsafePointer {
  var end: UnsafeRawPointer {
    UnsafeRawPointer(self + 1)
  }
}

extension UnsafeBufferPointer {
  var end: UnsafeRawPointer? {
    guard let base = baseAddress else {
      return nil
    }
    return UnsafeRawPointer(base + count)
  }

  var endAligned4: UnsafeRawPointer? {
    guard let base = baseAddress else {
      return nil
    }
    let trueEnd = UnsafeRawPointer(base + count)
    let uint = UInt(bitPattern: trueEnd)
    let aligned = alignUp4(uint)
    return UnsafeRawPointer(bitPattern: aligned)
  }
}
