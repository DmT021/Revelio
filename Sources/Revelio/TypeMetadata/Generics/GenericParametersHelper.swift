// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

func copyGenericArguments(
  metadataPtr: UnsafeRawPointer,
  offsetInWords: Int,
  numParams: Int
) -> [Any.Type] {
  Array(unsafeUninitializedCapacity: numParams) { buffer, initializedCount in
    initializedCount = numParams
    let genericArgumentsStart = metadataPtr
      .advanced(by: offsetInWords * MemoryLayout<UnsafeRawPointer>.size)
    let genericArguments = UnsafeBufferPointer(
      start: genericArgumentsStart.assumingMemoryBound(to: Any.Type.self),
      count: numParams
    )
    for i in 0..<numParams {
      buffer.initializeElement(
        at: i,
        to: genericArguments[i]
      )
    }
  }
}
