/// async_utils.dart
///
/// Utilities for async operations
///
/// Copyright (C) 2024 Potix Corporation. All Rights Reserved.
library async_utils;

/// Fire-and-forget async operation handler.
///
/// Use this when you intentionally want to ignore a Future result.
/// This is critical for operations that should not block execution
/// and where errors are handled by the caller's error handling.
///
/// Example:
/// ```dart
/// unawaited(someAsyncOperation());
/// ```
void unawaited(final Future<void> future) {
  // Intentionally ignore the future - this is fire-and-forget
  // Any errors will be handled by the caller's error handling
}
