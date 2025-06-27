// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

extension Metadata {
  public struct ObjCClassWrapper {
    typealias Pointee = _ObjCClassWrapperMetadata

    var ptr: UnsafePointer<Pointee>

    init(type: Any.Type) {
      ptr = unsafeBitCast(type, to: UnsafePointer<Pointee>.self)
    }

    public var `class`: Metadata.Class {
      ptr.pointee.class
    }
  }
}

/// The structure of wrapper metadata for Objective-C classes.  This
/// is used as a type metadata pointer when the actual class isn't
/// Swift-compiled.
struct _ObjCClassWrapperMetadata {
  var kind: Int

//  ConstTargetMetadataPointer<Runtime, TargetClassMetadataObjCInterop> Class;
  // This could be `Any.Type` but we know that it points to a class
  var `class`: Metadata.Class
}
