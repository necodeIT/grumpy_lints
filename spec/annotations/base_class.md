Subclasses of a class annotated with `BaseClass` have to follow the following rules:

- They are only allowed to be defined in the layers specified in [allowedLayers].
- They must have the name of the base class as a suffix.
- The file must be in a subdirectory named after the base class in plural snake_case (type_directory).
- The file the class is defined in must have the same name as the class in snake_case.
- The file must not contain any other classes (except for extensions or mixins).
- Classes defined in the type_directory must extend this base class.

Unit tests are exempt from these rules.

# Examples

All examples assume a base class defined as follows:

```dart
@BaseClass(
  allowedLayers: {.domain, .infra},
  typeDirectory: 'services',
)
abstract class Service {}
```

```dart
// Good: Correctly defined subclass in the domain layer.
// File path: lib/src/moodule/domain/services/user_service.dart
abstract class UserService extends Service {}
```

```dart
// Bad: Incorrect layer. Defined in the presentation layer.
// File path: lib/src/moodule/presentation/services/user_service.dart
abstract class UserService extends Service {}
```

```dart
// Bad: Incorrect file name. File name should be user_service.dart.
// File path: lib/src/moodule/domain/services/userService.dart
abstract class UserService extends Service {}
```

```dart
// Bad: File contains another class.
// File path: lib/src/moodule/domain/services/user_service.dart
abstract class UserService extends Service {}   

class AnotherClass {}
```

```dart
// Bad: Does not extend the base class.
// File path: lib/src/moodule/domain/services/user_service.dart
abstract class UserService {}
```

```dart
/// bad: Incorrect directory. Should be in 'services' subdirectory.
/// File path: lib/src/moodule/domain/user_service.dart
abstract class UserService extends Service {}
```

```dart
// bad: Does not have the base class name as a suffix.
// File path: lib/src/moodule/domain/services/user_manager.dart
abstract class UserManager extends Service {}
```
