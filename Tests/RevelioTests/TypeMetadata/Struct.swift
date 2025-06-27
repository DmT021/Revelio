// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

import Revelio
import Testing

struct StructMetadataTests {
  @Test
  func simpleStruct() throws {
    let typeMeta = Metadata(of: SimpleStruct.self)
    let structMeta = try #require(typeMeta?.asStruct)
    #expect(structMeta.descriptor.name == "SimpleStruct")
    #expect(structMeta.descriptor.numFields == 2)
    #expect(structMeta.descriptor.flags.isGeneric == false)
    #expect(structMeta.genericArguments.isEmpty)
    #expect(structMeta.descriptor.genericContext == nil)
  }

  @Test
  func genericStruct() throws {
    let typeMeta = Metadata(of: GenericStruct<Int, String>.self)
    let structMeta = try #require(typeMeta?.asStruct)
    #expect(structMeta.descriptor.name == "GenericStruct")
    #expect(structMeta.descriptor.numFields == 2)
    #expect(structMeta.descriptor.flags.isGeneric)
    #expect(structMeta.genericArguments
      .elementsEqual(
        [.type(Int.self), .type(String.self)],
        by: isEqualGenericArguments
      )
    )
    let genericContext = try #require(structMeta.descriptor.genericContext)
    #expect(genericContext.numParams == 2)
    #expect(genericContext.numRequirements == 1)
  }

  @Test
  func stdlibStruct() throws {
    let typeMeta = Metadata(of: Int.self)
    let structMeta = try #require(typeMeta?.asStruct)
    #expect(structMeta.descriptor.name == "Int")
    #expect(structMeta.descriptor.numFields == 1)
    #expect(structMeta.descriptor.flags.isGeneric == false)
    #expect(structMeta.genericArguments.isEmpty)
    #expect(structMeta.descriptor.genericContext == nil)
  }

  @Test
  func stdlibGenericStruct() throws {
    let typeMeta = Metadata(of: [Int].self)
    let structMeta = try #require(typeMeta?.asStruct)
    #expect(structMeta.descriptor.name == "Array")
    #expect(structMeta.descriptor.numFields == 1)
    #expect(structMeta.descriptor.flags.isGeneric == true)
    #expect(structMeta.genericArguments
      .elementsEqual(
        [.type(Int.self)],
        by: isEqualGenericArguments
      )
    )
    let genericContext = try #require(structMeta.descriptor.genericContext)
    #expect(genericContext.numParams == 1)
  }
}

extension Metadata {
  fileprivate var asStruct: Metadata.Struct? {
    switch self {
    case let .struct(meta): meta
    default: nil
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

func isEqualGenericArguments(lhs: GenericArgument?, rhs: GenericArgument?) -> Bool {
  switch (lhs, rhs) {
  case (.none, .none):
    return true
  case let (.some(lhs), .some(rhs)):
    return isEqualGenericArguments(lhs: lhs, rhs: rhs)
  case (.some, .none), (.none, .some):
    return false
  }
}

func isEqualGenericArguments(lhs: GenericArgument, rhs: GenericArgument) -> Bool {
  switch (lhs, rhs) {
  case let (.type(lhs), .type(rhs)):
    return lhs == rhs
  }
}
