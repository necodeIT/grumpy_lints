Classes like Services, Datasources, Repos, Mixins, etc should have their respective suffix in the name.

```dart
// BAD: class name is missing suffix
// File: lib/src/module/domain/services/user_service.dart
abstract class User  extends Service {}
```

```dart
// GOOD: class name includes suffix
// File: lib/src/module/domain/services/user_service.dart
abstract class UserService extends Service {}
```
