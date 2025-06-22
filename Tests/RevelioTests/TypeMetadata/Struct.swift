// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

import Revelio
import Testing

struct StructMetadataTests {
  @Test
  func simpleStruct() throws {
    let typeMeta = TypeMetadata(type: SimpleStruct.self)
    let structMeta = try #require(typeMeta?.asStruct)
    #expect(structMeta.descriptor.name == "SimpleStruct")
    #expect(structMeta.descriptor.numFields == 2)
    #expect(structMeta.descriptor.flags.isGeneric == false)
    #expect(structMeta.genericParameters.isEmpty)
    #expect(structMeta.descriptor.genericContext == nil)
  }

  @Test
  func genericStruct() throws {
    let typeMeta = TypeMetadata(type: GenericStruct<Int, String>.self)
    let structMeta = try #require(typeMeta?.asStruct)
    #expect(structMeta.descriptor.name == "GenericStruct")
    #expect(structMeta.descriptor.numFields == 2)
    #expect(structMeta.descriptor.flags.isGeneric)
    #expect(structMeta.genericParameters.elementsEqual([Int.self, String.self], by: ==))
    let genericContext = try #require(structMeta.descriptor.genericContext)
    #expect(genericContext.numParams == 2)
    #expect(genericContext.numRequirements == 1)
  }

  @Test
  func stdlibStruct() throws {
    let typeMeta = TypeMetadata(type: Int.self)
    let structMeta = try #require(typeMeta?.asStruct)
    #expect(structMeta.descriptor.name == "Int")
    #expect(structMeta.descriptor.numFields == 1)
    #expect(structMeta.descriptor.flags.isGeneric == false)
    #expect(structMeta.genericParameters.isEmpty)
    #expect(structMeta.descriptor.genericContext == nil)
  }

  @Test
  func stdlibGenericStruct() throws {
    let typeMeta = TypeMetadata(type: [Int].self)
    let structMeta = try #require(typeMeta?.asStruct)
    #expect(structMeta.descriptor.name == "Array")
    #expect(structMeta.descriptor.numFields == 1)
    #expect(structMeta.descriptor.flags.isGeneric == true)
    #expect(structMeta.genericParameters.elementsEqual([Int.self], by: ==))
    let genericContext = try #require(structMeta.descriptor.genericContext)
    #expect(genericContext.numParams == 1)
  }
}

extension TypeMetadata {
  fileprivate var asStruct: TypeMetadata.Struct? {
    switch self {
    case let .struct(meta): meta
    }
  }
}

private struct SimpleStruct {
  var foo: Int
  var bar: String
}

private struct GenericStruct<T, U: CustomStringConvertible> {
  var foo: T
  var bar: U
}
