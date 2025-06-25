// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

#include "include/objc_helper.h"

#if defined(__OBJC__)

#include <objc/NSObject.h>

Class _Nonnull revelio_getInitializedObjCClass(Class _Nonnull c) {
  // return swift_getInitializedObjCClass(c);
  return [c self];
}

#endif // defined(__OBJC__)
