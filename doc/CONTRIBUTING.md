# Contributing to socket_io

Thank you for your interest in contributing to socket_io! This document provides guidelines and instructions for contributing to the project.

---

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Setup](#development-setup)
4. [Coding Standards](#coding-standards)
5. [Testing Requirements](#testing-requirements)
6. [Pull Request Process](#pull-request-process)
7. [Architecture Guidelines](#architecture-guidelines)
8. [Common Tasks](#common-tasks)
9. [Release Process](#release-process)

---

## Code of Conduct

### Our Standards

- **Be respectful** and constructive in all interactions
- **Welcome newcomers** and help them get started
- **Focus on what is best** for the community and project
- **Show empathy** towards other community members
- **Accept constructive criticism** gracefully

### Unacceptable Behavior

- Harassment, discrimination, or offensive comments
- Trolling, insulting, or derogatory remarks
- Public or private harassment
- Publishing others' private information without permission

---

## Getting Started

### Prerequisites

- **Dart SDK**: >= 3.0.0 < 4.0.0
- **Git**: For version control
- **IDE**: VS Code, IntelliJ IDEA, or Android Studio (recommended)

### Fork and Clone

1. **Fork** the repository on GitHub
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/socket.io-dart.git
   cd socket.io-dart
   ```

3. **Add upstream** remote:
   ```bash
   git remote add upstream https://github.com/rikulo/socket.io-dart.git
   ```

4. **Install dependencies**:
   ```bash
   dart pub get
   ```

---

## Development Setup

### Install Development Tools

```bash
# Format checker
dart format --version

# Analyzer
dart analyze --version

# Test runner
dart test --version
```

### Verify Setup

Run all quality checks:

```bash
# Format check
dart format . --output none --set-exit-if-changed

# Analysis
dart analyze

# Tests
dart test
```

All commands should complete successfully.

---

## Coding Standards

### File Naming

- **Snake case** for files: `socket_options_models.dart`
- **PascalCase** for classes: `SocketOptionsModel`
- **camelCase** for variables and functions: `connectionId`, `buildHandshake()`

### Code Style

**Follow official Dart style guide**: https://dart.dev/guides/language/effective-dart/style

#### Formatting

```bash
# Format all Dart files
dart format .
```

Our configuration (in `analysis_options.yaml`):
- **Page width**: 120 characters
- **Trailing commas**: Preserved for better diffs

#### Naming Conventions

```dart
// Classes: PascalCase
class ConnectionManager { }

// Variables: camelCase
final connectionId = ConnectionId('123');

// Constants: lowerCamelCase
const defaultPort = 3000;

// Private: prefix with _
String _privateField;
void _privateMethod() { }
```

#### Import Organization

```dart
// 1. Dart imports
import 'dart:async';
import 'dart:io';

// 2. Package imports
import 'package:logging/logging.dart';
import 'package:socket_io_common/socket_io_common.dart';

// 3. Relative imports
import 'models/packet_models.dart';
import 'value_objects/connection_id_vo.dart';
```

#### Comments

```dart
/// Public API documentation (triple-slash)
/// 
/// Detailed description of the class/method.
/// 
/// Example:
/// ```dart
/// final socket = Socket(...);
/// socket.emit('event', ['data']);
/// ```
class Socket {
  // Implementation comments (double-slash)
  void _privateMethod() {
    // Explain complex logic here
  }
}
```

### Type Safety

#### Always Specify Types

```dart
// ✅ Good
final String name = 'socket';
final List<String> rooms = [];
final Map<String, dynamic> data = {};

// ❌ Avoid
var name = 'socket';  // Don't use var
final rooms = [];     // Missing type
```

#### Avoid Dynamic

```dart
// ✅ Good - Use specific types
void handleEvent(EventData data) { }
final Map<String, String> query = {};

// ❌ Avoid - Dynamic is not type-safe
void handleEvent(dynamic data) { }
final Map<String, dynamic> query = {};  // Only if truly needed
```

#### Null Safety

```dart
// ✅ Good - Explicit nullable types
String? optionalValue;
final String requiredValue = optionalValue ?? 'default';

// ✅ Good - Late initialization only when necessary
late final String lateValue;

// ❌ Avoid - Use nullable instead of late when possible
late String? confusing;  // Rarely needed
```

---

## Testing Requirements

### Test Coverage

**All new code must have tests** covering:

1. **Happy paths**: Normal usage scenarios
2. **Edge cases**: Null, empty, boundary values
3. **Error cases**: Invalid inputs, exceptions
4. **Type safety**: Ensure compile-time checking

### Test Organization

```dart
group('FeatureName', () {
  group('Method/Aspect', () {
    test('specific behavior description', () {
      // Arrange
      final instance = MyClass();
      
      // Act
      final result = instance.method();
      
      // Assert
      expect(result, equals(expected));
    });
  });
});
```

### Running Tests

```bash
# Run all tests
dart test

# Run specific test file
dart test test/models/packet_models_test.dart

# Run with coverage
dart test --coverage=coverage
```

### Test Naming

```dart
// ✅ Good - Descriptive test names
test('creates valid ConnectionId from non-empty string', () { });
test('throws ArgumentError when ID is empty', () { });
test('equality works correctly for same values', () { });

// ❌ Avoid - Vague test names
test('test1', () { });
test('works', () { });
```

### Example Test

```dart
import 'package:test/test.dart';
import 'package:socket_io/socket_io.dart';

void main() {
  group('ConnectionId', () {
    test('creates valid ConnectionId from non-empty string', () {
      final id = ConnectionId('test-123');
      expect(id.value, equals('test-123'));
    });
    
    test('throws ArgumentError for empty string', () {
      expect(() => ConnectionId(''), throwsArgumentError);
    });
    
    test('equality works correctly', () {
      final id1 = ConnectionId('test');
      final id2 = ConnectionId('test');
      final id3 = ConnectionId('other');
      
      expect(id1, equals(id2));
      expect(id1, isNot(equals(id3)));
    });
    
    test('hashCode is consistent', () {
      final id1 = ConnectionId('test');
      final id2 = ConnectionId('test');
      
      expect(id1.hashCode, equals(id2.hashCode));
    });
  });
}
```

---

## Pull Request Process

### Before Creating a PR

1. **Sync with upstream**:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run all checks**:
   ```bash
   dart format .
   dart analyze
   dart test
   ```

3. **Commit with clear messages**:
   ```bash
   git commit -m "feat: add binary data detection
   
   - Implement _containsBinaryData() method
   - Add recursive checking for nested structures
   - Update tests to cover new functionality"
   ```

### Commit Message Format

```
<type>: <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Test additions/changes
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `chore`: Maintenance tasks

**Examples:**
```
feat: add support for Redis adapter

Implements Redis-based adapter for distributed deployments.
Adds configuration options for Redis connection.

Closes #123
```

```
fix: correct secure connection detection

- Add X-Forwarded-Proto header support
- Handle platforms without connectionInfo
- Add tests for reverse proxy scenarios

Fixes #456
```

### Creating the PR

1. **Push to your fork**:
   ```bash
   git push origin feature-branch
   ```

2. **Create PR** on GitHub with:
   - **Clear title**: Describes the change
   - **Description**: What and why
   - **Related issues**: Link to issues
   - **Breaking changes**: If any
   - **Checklist**: All items completed

3. **PR Template** (automatically provided):
   ```markdown
   ## Description
   Brief description of changes
   
   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update
   
   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Tests added/updated
   - [ ] All tests pass
   - [ ] Documentation updated
   - [ ] No analysis warnings
   ```

### Review Process

1. **Automated checks** run (CI/CD)
2. **Maintainer review** (usually within 3 days)
3. **Address feedback** if requested
4. **Approval and merge**

---

## Architecture Guidelines

### When to Use What

#### Value Objects

Use for **validated primitives**:

```dart
// ✅ Good - Validation at construction
class RoomName {
  final String value;
  factory RoomName(String name) {
    if (name.isEmpty) throw ArgumentError('Room name cannot be empty');
    return RoomName._(name);
  }
  const RoomName._(this.value);
}

// When to create a value object:
// - Primitive needs validation
// - Domain concept with invariants
// - Needs special equality/hashCode
```

#### Domain Models

Use for **business logic**:

```dart
// ✅ Good - Rich model with behavior
class HandshakeDataModel {
  final HttpHeaders headers;
  final DateTime time;
  final InternetAddress address;
  
  // Business logic
  bool get isSecure => ...;
  String get userAgent => headers.value('user-agent') ?? 'unknown';
}

// When to create a model:
// - Multiple related fields
// - Business logic
// - Conversions (toMap, fromMap)
```

#### Extensions

Use for **utility methods**:

```dart
// ✅ Good - Non-intrusive utilities
extension PacketExtensions on SocketIOPacket {
  bool get isConnect => type == CONNECT;
  String get typeName => ...;
}

// When to use extensions:
// - Utility methods for existing types
// - Type-specific helpers
// - Cross-cutting concerns
```

#### Sealed Classes

Use for **closed type hierarchies**:

```dart
// ✅ Good - Exhaustive pattern matching
sealed class SocketIOError {
  String get message;
}

class TransportError extends SocketIOError { ... }
class ConnectionError extends SocketIOError { ... }

// When to use sealed classes:
// - Fixed set of subtypes
// - Pattern matching needed
// - Type safety at boundaries
```

### File Organization

#### Models Directory

```
models/
├── packet_models.dart           # Packet types
├── server_options_models.dart   # Configuration
├── error_models.dart            # Error types
├── callbacks_models.dart        # Callback typedefs
└── models.dart                  # Barrel export
```

#### Value Objects Directory

```
value_objects/
├── connection_id_vo.dart        # Connection ID
├── room_name_vo.dart            # Room name
└── value_objects.dart           # Barrel export
```

#### Naming Conventions

- Models: `*_models.dart` (e.g., `packet_models.dart`)
- Value Objects: `*_vo.dart` (e.g., `connection_id_vo.dart`)
- Extensions: `*_extensions.dart` (e.g., `map_extensions.dart`)
- Tests: `*_test.dart` (e.g., `packet_models_test.dart`)

---

## Common Tasks

### Adding a New Value Object

1. **Create file**: `lib/src/value_objects/my_value_vo.dart`

```dart
/// Documentation
class MyValue {
  final String value;
  
  const MyValue._(this.value);
  
  factory MyValue(String value) {
    // Validation
    if (value.isEmpty) {
      throw ArgumentError('MyValue cannot be empty');
    }
    return MyValue._(value);
  }
  
  const MyValue.unchecked(this.value);
  
  @override
  bool operator ==(Object other) =>
      other is MyValue && value == other.value;
  
  @override
  int get hashCode => value.hashCode;
  
  @override
  String toString() => value;
}
```

2. **Add to barrel export**: `lib/src/value_objects/value_objects.dart`

```dart
export 'my_value_vo.dart';
```

3. **Create tests**: `test/value_objects/my_value_vo_test.dart`

4. **Run checks**:
```bash
dart format lib/src/value_objects/my_value_vo.dart test/value_objects/my_value_vo_test.dart
dart analyze
dart test test/value_objects/my_value_vo_test.dart
```

### Adding a New Model

1. **Create file**: `lib/src/models/my_feature_models.dart`

2. **Implement model** with:
   - Factory constructors
   - `toMap()` / `fromMap()` methods
   - Equality and hashCode
   - `toString()` for debugging

3. **Add to barrel export**: `lib/src/models/models.dart`

4. **Create comprehensive tests**

### Adding an Extension

1. **Create file**: `lib/src/extensions/my_extension.dart`

```dart
extension MyTypeExtensions on MyType {
  ReturnType myMethod() {
    // Implementation
  }
}
```

2. **Add to barrel export**: `lib/src/extensions/extensions.dart`

3. **Test all methods**

### Fixing a Bug

1. **Write a failing test** that reproduces the bug
2. **Fix the code** to make the test pass
3. **Ensure no regressions** (all other tests still pass)
4. **Document the fix** in commit message

---

## Release Process

### Version Numbering

Follow **Semantic Versioning** (semver.org):

- **MAJOR**: Breaking changes (v1.0.0 → v2.0.0)
- **MINOR**: New features, backward compatible (v1.0.0 → v1.1.0)
- **PATCH**: Bug fixes, backward compatible (v1.0.0 → v1.0.1)

### Release Checklist

- [ ] All tests passing
- [ ] No analysis warnings
- [ ] CHANGELOG.md updated
- [ ] Version bumped in pubspec.yaml
- [ ] Documentation updated
- [ ] Git tag created
- [ ] Published to pub.dev (if applicable)

### Deprecation Policy

**3-version deprecation window**:

1. **v2.x**: Mark as `@Deprecated('Use newMethod instead. Will be removed in v4.0')`
2. **v3.x**: Keep deprecated, add runtime warnings
3. **v4.x**: Remove deprecated code (breaking change)

---

## Getting Help

### Resources

- **Documentation**: See README.md and ARCHITECTURE.md
- **Issues**: https://github.com/rikulo/socket.io-dart/issues
- **Discussions**: GitHub Discussions
- **Socket.IO Docs**: https://socket.io/docs/

### Questions?

- **Check existing issues** first
- **Ask in Discussions** for general questions
- **Open an issue** for bugs or feature requests
- **Tag maintainers** if urgent

---

## Recognition

Contributors are recognized in:
- **README.md** Contributors section
- **Git history** (commit authorship)
- **Release notes** for significant contributions

Thank you for contributing to socket_io! 🎉

---

**Last Updated:** 2025-10-11  
**Version:** 1.0
