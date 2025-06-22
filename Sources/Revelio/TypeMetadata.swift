//
//  TypeMetadata.swift
//  Revelio
//
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

public enum TypeMetadata {
  case `struct`(Struct)

  public init?(type: Any.Type) {
    let kind = MetadataKind(type)
    switch kind {
    case .struct:
      self = .struct(Struct(type: type))
    default:
      return nil
    }
  }
}
