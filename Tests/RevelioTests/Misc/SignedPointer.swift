// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

import Revelio
import Testing

struct UnsafeRawSignedPointerTests {
  @Test
  func optionalAndNonOptionalMemoryLayoutMatch() {
    typealias P = UnsafeRawSignedPointer<PtrAuthKeys.ProcessIndependentData>
    typealias NonOptionalML = MemoryLayout<P>
    typealias OptionalML = MemoryLayout<P?>

    #expect(NonOptionalML.size == OptionalML.size)
    #expect(NonOptionalML.stride == OptionalML.stride)
    #expect(NonOptionalML.alignment == OptionalML.alignment)
  }
}
