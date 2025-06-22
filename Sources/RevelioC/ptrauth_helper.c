// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

#include "include/ptrauth_helper.h"
#include <stdbool.h>

// https://clang.llvm.org/docs/PointerAuthentication.html#feature-testing
#define HAS_PTRAUTH __has_feature(ptrauth_intrinsics)

#if HAS_PTRAUTH

const _Bool has_ptrauth = true;

#include <ptrauth.h>

#define KEY(k) \
const void *revelio_ptrauth_strip_##k(const void *ptr) {\
  return ptrauth_strip(ptr, ptrauth_key_##k);\
}
#include "ptrauth_keys.def"

#else  // HAS_PTRAUTH

const _Bool has_ptrauth = false;

#define KEY(k) \
const void *revelio_ptrauth_strip_##k(const void *ptr) {\
  return ptr;\
}
#include "ptrauth_keys.def"

#endif  // HAS_PTRAUTH
