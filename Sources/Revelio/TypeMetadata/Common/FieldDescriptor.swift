// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

public struct FieldDescriptorPointer {
  typealias Pointee = _FieldDescriptor

  var ptr: UnsafePointer<Pointee>

  init(ptr: UnsafePointer<Pointee>) {
    self.ptr = ptr
  }

  public var mangledTypeName: UnsafePointer<CChar>? {
    RelativeDirectPointer
      .resolve(from: ptr, keypath: \.mangledTypeName)
  }

  public var superclass: UnsafePointer<CChar>? {
    RelativeDirectPointer
      .resolve(from: ptr, keypath: \.superclass)
  }

  public var __mangledTypeName: __MangledName? {
    mangledTypeName.map {
      __MangledName($0)
    }
  }

  public var __superclass: __MangledName? {
    superclass.map {
      __MangledName($0)
    }
  }

  public var kind: FieldDescriptorKind? {
    FieldDescriptorKind(rawKind: ptr.pointee.kind)
  }

  public var numFields: Int {
    let n = ptr.pointee.numFields
    return Int(n)
  }

  public var fields: [(flags: FieldRecordFlags, name: String?, mangledType: String?)] {
    let start = ptr.end.assumingMemoryBound(to: _FieldRecord.self)
    let numFields = numFields
    return (0..<numFields).map { i in
      let p = start.advanced(by: i)
      let namePtr = p.pointee.fieldName.pointer(from: p.pointer(to: \.fieldName)!)
      let name = namePtr.map { String(cString: $0) }
      let mangledTypePtr = p.pointee.mangledTypeName
        .pointer(from: p.pointer(to: \.mangledTypeName)!)
      let mangledType = mangledTypePtr.map { String(cString: $0) }
      return (
        flags: p.pointee.flags,
        name: name,
        mangledType: mangledType
      )
    }
  }
}

// include/swift/RemoteInspection/Records.h
struct _FieldDescriptor {
  // const TargetRelativeDirectPointer<Runtime, const char> MangledTypeName;
  let mangledTypeName: RelativeDirectPointer<Int32, CChar>

  // const TargetRelativeDirectPointer<Runtime, const char> Superclass;
  let superclass: RelativeDirectPointer<Int32, CChar>

  //  const FieldDescriptorKind Kind;
  let kind: _FieldDescriptorKind

  //  const uint16_t FieldRecordSize;
  let fieldRecordSize: UInt16

  //  const uint32_t NumFields;
  let numFields: UInt32
}

// Field records describe the type of a single stored property or case member
// of a class, struct or enum.
public struct FieldRecordFlags {
  var value: UInt32

  public var isIndirectCase: Bool {
    value & 1 != 0
  }

  public var isVar: Bool {
    value & 2 != 0
  }

  public var isArtificial: Bool {
    value & 4 != 0
  }
}

struct _FieldRecord {
  let flags: FieldRecordFlags

  // const TargetRelativeDirectPointer<Runtime, const char> MangledTypeName;
  let mangledTypeName: RelativeDirectPointer<Int32, CChar>

  // const TargetRelativeDirectPointer<Runtime, const char> FieldName;
  let fieldName: RelativeDirectPointer<Int32, CChar>
}

struct _FieldDescriptorKind {
  var value: UInt16
}

public enum FieldDescriptorKind {
  // Swift nominal types.
  case `struct`
  case `class`
  case `enum`

  // Fixed-size multi-payload enums have a special descriptor format that
  // encodes spare bits.
  //
  // FIXME: Actually implement this. For now, a descriptor with this kind
  // just means we also have a builtin descriptor from which we get the
  // size and alignment.
  case multiPayloadEnum

  // A Swift opaque protocol. There are no fields, just a record for the
  // type itself.
  case `protocol`

  // A Swift class-bound protocol.
  case classProtocol

  // An Objective-C protocol, which may be imported or defined in Swift.
  case objCProtocol

  // An Objective-C class, which may be imported or defined in Swift.
  // In the former case, field type metadata is not emitted, and
  // must be obtained from the Objective-C runtime.
  case objCClass

  init?(rawKind: _FieldDescriptorKind) {
    switch rawKind.value {
    case 0: self = .struct
    case 1: self = .class
    case 2: self = .enum
    case 3: self = .multiPayloadEnum
    case 4: self = .protocol
    case 5: self = .classProtocol
    case 6: self = .objCProtocol
    case 7: self = .objCClass
    default: return nil
    }
  }
}

public struct __MangledName {
  public enum Part {
    case string(String)
    case uint32(UInt8, UInt32)
    case pointer(UInt8, UnsafeRawPointer)
  }

  public var parts: [Part]

  init(_ s: UnsafePointer<CChar>) {
    var e = s
    var stringStart: UnsafePointer<CChar>?
    var parts = [Part]()

    func saveString() {
      if let stringStart {
        let length = e - stringStart
        let buf = UnsafeBufferPointer(
          start: stringStart,
          count: length
        )
        let str = String(
          decoding: buf.map { UInt8(bitPattern: $0) },
          as: UTF8.self
        )
        parts.append(.string(str))
      }
      stringStart = nil
    }

    while true {
      let c = e.pointee
      if c == 0 {
        saveString()
        break
      } else if c >= 1, c <= 0x17 {
        saveString()
        e += 1
        let d = UnsafeRawPointer(e).assumingMemoryBound(to: UInt32.self).pointee
        parts.append(.uint32(UInt8(c), d))
        e += MemoryLayout<UInt32>.size
      } else if c >= 0x18, c <= 0x1F {
        saveString()
        e += 1
        let d = UnsafeRawPointer(e).assumingMemoryBound(to: UnsafeRawPointer.self).pointee
        parts.append(.pointer(UInt8(c), d))
        e += MemoryLayout<UnsafeRawPointer>.size
      } else {
        e += 1
      }
    }

    self.parts = parts
  }
}
