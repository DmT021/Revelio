// Revelio
// Created by Dmitrii Galimzianov.
// Copyright © 2025 Dmitrii Galimzianov. All rights reserved.

#ifndef OBJC_HELPER_H
#define OBJC_HELPER_H

#if defined(__OBJC__)
#include <objc/runtime.h>

Class _Nonnull revelio_getInitializedObjCClass(Class _Nonnull c);

#endif // defined(__OBJC__)

#endif // OBJC_HELPER_H
