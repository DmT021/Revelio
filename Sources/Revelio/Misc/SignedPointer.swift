// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

import RevelioC

public protocol PtrAuthKey {
  static func strip(_ ptr: OpaquePointer) -> UnsafeRawPointer
}

public enum PtrAuthKeys {
  public enum ProcessIndependentData: PtrAuthKey {
    public static func strip(_ ptr: OpaquePointer) -> UnsafeRawPointer {
      revelio_ptrauth_strip_process_independent_data(UnsafeRawPointer(ptr))
    }
  }

  public enum FunctionPointer: PtrAuthKey {
    public static func strip(_ ptr: OpaquePointer) -> UnsafeRawPointer {
      revelio_ptrauth_strip_function_pointer(UnsafeRawPointer(ptr))
    }
  }
}

public struct UnsafeRawSignedPointer<Key: PtrAuthKey> {
  public var raw: OpaquePointer

  public var stripped: UnsafeRawPointer {
    // We could check `#if _ptrauth(_arm64e)` to see if we have
    // PAC available and need to perform stripping.
    // But I'd rather avoid usage of undocumented API if possible.
    // So the check is in the C portion of the library
    // and `strip` functions are no-op if we don't have PAC.
    Key.strip(raw)
  }
}
