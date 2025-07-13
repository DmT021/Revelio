// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

@testable import Revelio
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

    let fieldsDescriptor = try #require(structMeta.descriptor.fieldsDescriptor)
    #expect(fieldsDescriptor.mangledTypeName != nil)
    #expect(fieldsDescriptor.superclass == nil)
    #expect(fieldsDescriptor.kind == .struct)
    #expect(fieldsDescriptor.numFields == 2)
    let fields = fieldsDescriptor.fields
    let field0 = fields[0]
    #expect(field0.flags.isVar)
    #expect(!field0.flags.isIndirectCase)
    #expect(!field0.flags.isArtificial)
    #expect(field0.name == "foo")
    #expect(field0.mangledType == "Si")
    let field1 = fields[1]
    #expect(!field1.flags.isVar)
    #expect(!field1.flags.isIndirectCase)
    #expect(!field1.flags.isArtificial)
    #expect(field1.name == "bar")
    #expect(field1.mangledType == "SS")
  }

  @Test
  func genericStruct() throws {
    let typeMeta = Metadata(of: GenericStruct<Int, String>.self)
    let structMeta = try #require(typeMeta?.asStruct)
    #expect(structMeta.descriptor.name == "GenericStruct")
    #expect(structMeta.descriptor.numFields == 2)
    #expect(structMeta.descriptor.flags.isGeneric)
    #expect(
      structMeta.genericArguments
        .elementsEqual(
          [.type(Int.self), .type(String.self)],
          by: isEqualGenericArguments
        )
    )
    let genericContext = try #require(structMeta.descriptor.genericContext)
    #expect(genericContext.numParams == 2)
    #expect(genericContext.numRequirements == 1)

    let gr = try #require(structMeta.descriptor.genericRequirementDescriptors)
    #expect(gr.count == 1)
    #expect(gr[0].flags.kind == .protocol)
    #expect(!gr[0].payloadUnion.protocol.isObjC)
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
    #expect(
      structMeta.genericArguments
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
  let bar: String
}

private struct GenericStruct<T, U: CustomStringConvertible> {
  var foo: T
  var bar: U
}

func isEqualGenericArguments(lhs: GenericArgument?, rhs: GenericArgument?) -> Bool {
  switch (lhs, rhs) {
  case (.none, .none):
    true
  case let (.some(lhs), .some(rhs)):
    isEqualGenericArguments(lhs: lhs, rhs: rhs)
  case (.some, .none), (.none, .some):
    false
  }
}

func isEqualGenericArguments(lhs: GenericArgument, rhs: GenericArgument) -> Bool {
  switch (lhs, rhs) {
  case let (.type(lhs), .type(rhs)):
    lhs == rhs
  }
}
