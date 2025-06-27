//
//  Metadata.swift
//  Revelio
//
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

public enum Metadata {
  case `struct`(Struct)
  case `class`(Class)
  case objcClassWrapper(ObjCClassWrapper)

  public init?(of: Any.Type) {
    let kind = MetadataKind(of)
    switch kind {
    case .struct:
      self = .struct(Struct(type: of))
    case .class:
      self = .class(Class(type: of))
    case .objcClassWrapper:
      self = .objcClassWrapper(ObjCClassWrapper(type: of))
    default:
      return nil
    }
  }
}
