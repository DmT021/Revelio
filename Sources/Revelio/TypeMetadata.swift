//
//  TypeMetadata.swift
//  Revelio
//
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

// TODO: rename to just Metadata
public enum TypeMetadata {
  case `struct`(Struct)
  case `class`(Class)
  case objcClassWrapper(ObjCClassWrapper)

  public init?(type: Any.Type) {
    let kind = MetadataKind(type)
    switch kind {
    case .struct:
      self = .struct(Struct(type: type))
    case .class:
      self = .class(Class(type: type))
    case .objcClassWrapper:
      self = .objcClassWrapper(ObjCClassWrapper(type: type))
    default:
      return nil
    }
  }
}
