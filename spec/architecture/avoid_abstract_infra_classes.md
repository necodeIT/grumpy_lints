# Avoid Abstract Infra Classes

## Intent
Ensure infra is made of concrete implementations. Abstractions belong in the
Domain layer; infra should implement them directly.

## Rule
Classes in `infra/` must not be declared `abstract`.

This includes infra services, datasources, and other infra implementation
classes.

## Rationale
Abstract infra classes blur the boundary between contracts (domain) and
implementations (infra). Keeping infra concrete makes DI and testing clearer,
and avoids accidental inheritance-based coupling inside infra.

## Allowed
- Abstract classes in `domain/` as contracts.
- Private helpers (top-level functions or private classes) inside infra.
- Mixins for sharing code within a module.

## Examples

```dart
// BAD: infra class is abstract
// File: lib/src/module/infra/services/my_user_service.dart
abstract class MyUserService extends UserService {}
```

```dart
// GOOD: infra class is concrete
// File: lib/src/module/infra/services/my_user_service.dart
class MyUserService extends UserService {}
```

```dart
// GOOD: use a mixin or private helper for shared behavior
// File: lib/src/module/infra/services/my_user_service.dart
mixin _LoggingMixin {
  void log(String message) {}
}

class MyUserService extends UserService with _LoggingMixin {}
```

## Notes
If you feel the need for an abstract infra base class, it is usually a sign
that the abstraction belongs in `domain/`, or that a mixin/private helper would
be a better fit.
