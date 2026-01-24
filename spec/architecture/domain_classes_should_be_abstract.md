# Domain Classes Should Be Abstract

## Intent
Treat domain services and datasources as contracts. Domain classes define the
API; infra provides concrete implementations.

## Rule
Classes in `domain/services` and `domain/datasources` must be declared
`abstract`.

This rule does **not** apply to domain models (DTOs/entities), which should be
concrete.

## Rationale
Abstract domain contracts enforce dependency inversion and prevent direct
instantiation in presentation or infra. This keeps boundaries explicit and
makes it easy to swap implementations.

## Examples

```dart
// BAD: domain service is concrete
// File: lib/src/module/domain/services/user_service.dart
class UserService extends Service {}
```

```dart
// GOOD: domain service is abstract
// File: lib/src/module/domain/services/user_service.dart
abstract class UserService extends Service {}
```

```dart
// GOOD: concrete implementation in infra
// File: lib/src/module/infra/services/my_user_service.dart
class MyUserService extends UserService {}
```

```dart
// GOOD: domain model stays concrete
// File: lib/src/module/domain/models/user.dart
class User {
  final String id;
  User(this.id);
}
```

## Notes
If you need shared behavior between domain contracts, use mixins or default
implementations in separate helper classes, but keep the contracts abstract.
