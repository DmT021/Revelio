// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

func copyGenericArguments(
  metadataPtr: UnsafeRawPointer,
  offsetInWords: Int,
  params: some Collection<_GenericParamDescriptor>
) -> [GenericArgument?] {
  let numParams = params.count
  return Array(unsafeUninitializedCapacity: numParams) { buffer, initializedCount in
    initializedCount = numParams
    let genericArgumentsStart = metadataPtr
      .advanced(by: offsetInWords * MemoryLayout<UnsafeRawPointer>.size)
    for (i, param) in params.enumerated() {
      let argument: GenericArgument?
      switch param.kind {
      case .none:
        argument = nil
      case .type:
        argument = .type(
          (genericArgumentsStart + i * MemoryLayout<UnsafeRawPointer>.size)
            .assumingMemoryBound(to: Any.Type.self)
            .pointee
        )
      case .typePack:
        argument = nil
      case .value:
        argument = nil
      }
      buffer.initializeElement(
        at: i,
        to: argument
      )
    }
  }
}
