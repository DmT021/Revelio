// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

@testable import Revelio
import RevelioC
import Testing

struct EnumMetadataTests {
  @Test
  func optional() throws {
    let typeMeta = Metadata(of: Int?.self)
    let meta = try #require(typeMeta?.asEnum)
    #expect(meta.descriptor.name == "Optional")
    #expect(meta.descriptor.numEmptyCases == 1)
    #expect(meta.descriptor.numPayloadCases == 1)
    #expect(meta.payloadSize == nil)
    #expect(meta.descriptor.flags.isGeneric == true)
    #expect(
      meta.genericArguments
        .elementsEqual(
          [.type(Int.self)],
          by: isEqualGenericArguments
        )
    )
    let genericContext = try #require(meta.descriptor.genericContext)
    #expect(genericContext.numParams == 1)
    #expect(genericContext.numRequirements == 1)
  }

  @Test
  func simple() throws {
    let typeMeta = Metadata(of: SimpleEnum.self)
    let meta = try #require(typeMeta?.asEnum)
    #expect(meta.descriptor.name == "SimpleEnum")
    #expect(meta.descriptor.numEmptyCases == 2)
    #expect(meta.descriptor.numPayloadCases == 0)
    #expect(meta.payloadSize == nil)
    #expect(meta.descriptor.flags.isGeneric == false)
    #expect(meta.genericArguments.isEmpty)
    #expect(meta.descriptor.genericContext == nil)
  }

  @Test
  func generic() throws {
    let typeMeta = Metadata(of: GenericEnum<Int, String>.self)
    let meta = try #require(typeMeta?.asEnum)
    #expect(meta.descriptor.name == "GenericEnum")
    #expect(meta.descriptor.numEmptyCases == 0)
    #expect(meta.descriptor.numPayloadCases == 2)
    #expect(meta.payloadSize == 16)
    #expect(meta.descriptor.flags.isGeneric)
    #expect(
      meta.genericArguments
        .elementsEqual(
          [.type(Int.self), .type(String.self)],
          by: isEqualGenericArguments
        )
    )
    let genericContext = try #require(meta.descriptor.genericContext)
    #expect(genericContext.numParams == 2)
    #expect(genericContext.numRequirements == 1)
  }
}

extension Metadata {
  fileprivate var asEnum: Metadata.Enum? {
    switch self {
    case let .enum(meta): meta
    default: nil
    }
  }
}

private enum SimpleEnum {
  case foo, bar
}

private enum GenericEnum<T, U: CustomStringConvertible> {
  case foo(T), bar(U)
}
