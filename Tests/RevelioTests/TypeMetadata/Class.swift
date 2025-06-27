// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

#if canImport(ObjectiveC)
import ObjectiveC
#endif
import Revelio
import Testing

struct ClassMetadataTests {
  @Test
  func simpleClass() throws {
    let typeMeta = Metadata(of: SimpleClass.self)
    let classMeta = try #require(typeMeta?.asClass)

    #if canImport(ObjectiveC)
    #expect(classMeta.superclass != nil) // TODO: can it be compared to Swift._SwiftObject?
    #else
    #expect(classMeta.superclass == nil)
    #endif

    let swiftSpecificClassMeta = try #require(classMeta.swift)
    let flags = swiftSpecificClassMeta.flags
    #expect(!flags.hasCustomObjCName)
    #expect(!flags.isSwiftPreStableABI)
    #expect(flags.usesSwiftRefcounting)

    #expect(swiftSpecificClassMeta.instanceSize == 24)
    #expect(swiftSpecificClassMeta.instanceAlignMask == 7)
    #expect(swiftSpecificClassMeta.classSize == 144)

    let descriptor = swiftSpecificClassMeta.descriptor
    #expect(descriptor.name == "SimpleClass")
    #expect(descriptor.numFields == 1)
    #expect(descriptor.flags.isGeneric == false)
    #expect(descriptor.genericContext == nil)
    let genericArguments = try #require(swiftSpecificClassMeta.genericArguments)
    #expect(genericArguments.isEmpty)
  }

  @Test
  func genericClass() throws {
    let typeMeta = Metadata(of: GenericClass<Int, String>.self)
    let classMeta = try #require(typeMeta?.asClass)

    let superclass = try #require(classMeta.superclass)
    let superclassIsExpected = superclass == SimpleClass.self
    #expect(superclassIsExpected)

    let swiftSpecificClassMeta = try #require(classMeta.swift)
    let flags = swiftSpecificClassMeta.flags
    #expect(!flags.hasCustomObjCName)
    #expect(!flags.isSwiftPreStableABI)
    #expect(flags.usesSwiftRefcounting)

    #expect(swiftSpecificClassMeta.instanceSize == 48)
    #expect(swiftSpecificClassMeta.instanceAlignMask == 7)
    #expect(swiftSpecificClassMeta.classSize == 240)

    let descriptor = swiftSpecificClassMeta.descriptor
    #expect(descriptor.name == "GenericClass")
    #expect(descriptor.numFields == 2)
    #expect(descriptor.flags.isGeneric == true)

    let genericContext = try #require(descriptor.genericContext)
    #expect(genericContext.numParams == 2)
    #expect(genericContext.numRequirements == 1)
    #expect(genericContext.numKeyArguments == 3)
    let genericArguments = try #require(swiftSpecificClassMeta.genericArguments)
    #expect(genericArguments
      .elementsEqual(
        [.type(Int.self), .type(String.self)],
        by: isEqualGenericArguments
      )
    )
  }

  @Test
  func classWithResilientSuperclass() throws {
    let typeMeta = Metadata(of: ClassWithResilientSuperclass<Int>.self)
    let classMeta = try #require(typeMeta?.asClass)

    let swiftSpecificClassMeta = try #require(classMeta.swift)
    let flags = swiftSpecificClassMeta.flags
    #expect(!flags.hasCustomObjCName)
    #expect(!flags.isSwiftPreStableABI)
    #expect(flags.usesSwiftRefcounting)

    let descriptor = swiftSpecificClassMeta.descriptor
    #expect(descriptor.name == "ClassWithResilientSuperclass")
    #expect(descriptor.flags.isGeneric == true)

    let genericContext = try #require(descriptor.genericContext)
    #expect(genericContext.numParams == 1)
    #expect(genericContext.numRequirements == 0)
    #expect(genericContext.numKeyArguments == 1)
    let genericArguments = try #require(swiftSpecificClassMeta.genericArguments)
    #expect(genericArguments
      .elementsEqual(
        [.type(Int.self)],
        by: isEqualGenericArguments
      )
    )
  }

  #if canImport(ObjectiveC)
  @Test
  func nsobject() throws {
    let typeMeta = Metadata(of: NSObject.self)
    let objcClassWrapperMeta = try #require(typeMeta?.asObjCClassWrapper)
    let classMeta = objcClassWrapperMeta.class
    #expect(classMeta.superclass == nil)
    #expect(classMeta.swift == nil)
  }
  #endif

  @Test
  func parameterPack() throws {
    let typeMeta = Metadata(of: ClassWithParameterPack<Int, String>.self)
    let classMeta = try #require(typeMeta?.asClass)

    let swiftSpecificClassMeta = try #require(classMeta.swift)
    let flags = swiftSpecificClassMeta.flags
    #expect(!flags.hasCustomObjCName)
    #expect(!flags.isSwiftPreStableABI)
    #expect(flags.usesSwiftRefcounting)

    let descriptor = swiftSpecificClassMeta.descriptor
    #expect(descriptor.name == "ClassWithParameterPack")
    #expect(descriptor.numFields == 1)
    #expect(descriptor.flags.isGeneric == true)

    let genericContext = try #require(descriptor.genericContext)
    #expect(genericContext.numParams == 1)
    #expect(genericContext.numRequirements == 0)
    #expect(genericContext.numKeyArguments == 2)

    let genericArguments = try #require(swiftSpecificClassMeta.genericArguments)
    #expect(genericArguments.elementsEqual(
      [nil],
      by: isEqualGenericArguments
    ))
  }

  @Test
  func classWithParameterPackAndResilientSuperclass() throws {
    typealias TestType = ClassWithParameterPackAndResilientSuperclass<Int, String>
    let type = TestType.self
    let typeMeta = Metadata(of: type)
    let classMeta = try #require(typeMeta?.asClass)

    let swiftSpecificClassMeta = try #require(classMeta.swift)
    let flags = swiftSpecificClassMeta.flags
    #expect(!flags.hasCustomObjCName)
    #expect(!flags.isSwiftPreStableABI)
    #expect(flags.usesSwiftRefcounting)

    let descriptor = swiftSpecificClassMeta.descriptor
    #expect(descriptor.name == "ClassWithParameterPackAndResilientSuperclass")
    #expect(descriptor.numFields == 0)
    #expect(descriptor.flags.isGeneric == true)

    let genericContext = try #require(descriptor.genericContext)
    #expect(genericContext.numParams == 1)
    #expect(genericContext.numRequirements == 0)
    #expect(genericContext.numKeyArguments == 2)

    let genericArguments = try #require(swiftSpecificClassMeta.genericArguments)
    #expect(genericArguments.elementsEqual(
      [nil],
      by: isEqualGenericArguments
    ))

  }
}

extension Metadata {
  fileprivate var asClass: Metadata.Class? {
    switch self {
    case let .class(meta): meta
    default: nil
    }
  }

  fileprivate var asObjCClassWrapper: Metadata.ObjCClassWrapper? {
    switch self {
    case let .objcClassWrapper(meta): meta
    default: nil
    }
  }
}

private class SimpleClass {
  var foo: Int

  init(foo: Int) {
    self.foo = foo
  }
}

private class GenericClass<T, U: CustomStringConvertible>: SimpleClass {
  var bar: T
  var buz: U

  init(foo: Int, bar: T, buz: U) {
    self.bar = bar
    self.buz = buz
    super.init(foo: foo)
  }
}

private class ClassWithResilientSuperclass<T>: ManagedBuffer<T, Void> {}

private class ClassWithParameterPack<each T> {
  var foo: (repeat each T)

  init(foo: repeat each T) {
    self.foo = (repeat each foo)
  }
}

private class ClassWithParameterPackAndResilientSuperclass<each T>: ManagedBuffer<Void, Void> {
  typealias Ts = (repeat each T)
}
