Classes that are in the layer type directories (like services, datasources, repos, etc) should extend their respective base layer type.

```dart
// BAD: class does not extend layer type
// File: lib/src/module/domain/services/user_service.dart
abstract class UserService {}
```

```dart
// GOOD: class extends layer type
// File: lib/src/module/domain/services/user_service.dart
abstract class UserService extends Service {}
```

```dart
// GOOD: class extends base class through another class
// File: lib/src/module/infra/services/my_user_service.dart

class MyUserService extends UserService {}
```
