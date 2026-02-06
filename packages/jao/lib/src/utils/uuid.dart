/// UUID generation utilities.
///
/// Provides a simple UUID v4 generator without external dependencies.
library;

import 'dart:math';

/// Generates a random UUID v4 string.
///
/// Example output: `550e8400-e29b-41d4-a716-446655440000`
String generateUuidV4() {
  final random = Random.secure();

  // Generate 16 random bytes
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));

  // Set version to 4 (random UUID)
  bytes[6] = (bytes[6] & 0x0f) | 0x40;

  // Set variant to RFC 4122
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  // Convert to hex string with dashes
  return '${_hex(bytes, 0, 4)}-${_hex(bytes, 4, 6)}-${_hex(bytes, 6, 8)}-${_hex(bytes, 8, 10)}-${_hex(bytes, 10, 16)}';
}

String _hex(List<int> bytes, int start, int end) {
  return bytes.sublist(start, end).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
