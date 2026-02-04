# Class Missing Suffix

## Intent

Keep domain and infra classes consistently named by enforcing expected suffixes
(e.g., `Service`, `Datasource`, `Repository`, `Mixin`).

## Rule

Classes like services, datasources, repositories, mixins, etc. must include
their respective suffix in the class name.

## Rationale

Consistent suffixes make architecture boundaries more readable and reduce
confusion when scanning files and logs.

## Examples

```dart
// BAD: class name is missing suffix
// File: lib/src/module/domain/services/user_service.dart
abstract class User extends Service {}
```

```dart
// GOOD: class name includes suffix
// File: lib/src/module/domain/services/user_service.dart
abstract class UserService extends Service {}
```
