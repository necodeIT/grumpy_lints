# Base Class

## Intent

Enforce consistent placement, naming, and structure for subclasses of a
`@BaseClass` contract.

## Rule

Subclasses of a class annotated with `@BaseClass` must follow these rules:

- They are only allowed to be defined in the layers specified in
  `allowedLayers`.
- They must have the base class name as a suffix.
- The file must be in a subdirectory named after the base class in plural
  snake_case (`typeDirectory`).
- The file the class is defined in must have the same name as the class in
  snake_case.
- The file must not contain any other classes (except extensions or mixins).
- Classes defined in the `typeDirectory` must extend the base class.

Unit tests are exempt from these rules.

## Rationale

This keeps module structure predictable, reduces accidental layering violations,
and ensures type directories only contain the intended subclasses.

## Examples

All examples assume a base class defined as follows:

```dart
@BaseClass(
  allowedLayers: {.domain, .infra},
  typeDirectory: 'services',
)
abstract class Service {}
```

```dart
// GOOD: Correctly defined subclass in the domain layer.
// File path: lib/src/module/domain/services/user_service.dart
abstract class UserService extends Service {}
```

```dart
// BAD: Incorrect layer. Defined in the presentation layer.
// File path: lib/src/module/presentation/services/user_service.dart
abstract class UserService extends Service {}
```

```dart
// BAD: Incorrect file name. File name should be user_service.dart.
// File path: lib/src/module/domain/services/userService.dart
abstract class UserService extends Service {}
```

```dart
// BAD: File contains another class.
// File path: lib/src/module/domain/services/user_service.dart
abstract class UserService extends Service {}

class AnotherClass {}
```

```dart
// BAD: Does not extend the base class.
// File path: lib/src/module/domain/services/user_service.dart
abstract class UserService {}
```

```dart
// BAD: Incorrect directory. Should be in 'services' subdirectory.
// File path: lib/src/module/domain/user_service.dart
abstract class UserService extends Service {}
```

```dart
// BAD: Does not have the base class name as a suffix.
// File path: lib/src/module/domain/services/user_manager.dart
abstract class UserManager extends Service {}
```
