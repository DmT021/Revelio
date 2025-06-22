// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

#ifndef PTRAUTH_HELPER_H
#define PTRAUTH_HELPER_H

extern const _Bool has_ptrauth;

#define KEY(k) const void *revelio_ptrauth_strip_##k(const void *ptr);
#include "ptrauth_keys.def"

#endif  // PTRAUTH_HELPER_H
