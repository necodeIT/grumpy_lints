# Keep Modules Atomic

## Intent

Keep module boundaries strict by avoiding inheritance that pulls implementation
behavior from another module. This prevents cross-module coupling and preserves
swap-ability of modules.

## Rule

Infra classes must not extend classes defined in another module.

This applies to classes under `infra/` (services, datasources, and other infra
implementations). Inheritance is allowed only within the same module.

## Rationale

Inheritance creates a strong, compile-time dependency on a concrete
implementation. If infra classes extend infra or domain types from another
module, the module boundary is effectively broken and refactors cascade across
modules.

## Examples

```dart
// BAD: infra class extends domain class from another module
// File: lib/src/module_a/infra/services/my_user_service.dart
import 'package:module_b/src/module/domain/services/user_service.dart';
class MyUserService extends UserService {}
```

```dart
// BAD: infra class extends infra class from another module
// File: lib/src/module_a/infra/services/my_user_service.dart
import 'package:module_b/src/module/infra/services/base_user_service.dart';
class MyUserService extends BaseUserService {}
```

```dart
// GOOD: infra class extends domain class from the same module
// File: lib/src/module_a/infra/services/my_user_service.dart
import 'package:module_a/src/module/domain/services/user_service.dart';
class MyUserService extends UserService {}
```

```dart
// GOOD: depend on another module by composition/DI
// File: lib/src/module_a/infra/services/my_user_service.dart
import 'package:module_b/src/module/domain/services/user_service.dart';

class MyUserService {
  final UserService other;
  MyUserService(this.other);
}
```

## Notes

If you need shared infra behavior across modules, move it to a shared package
or a dedicated common module rather than extending across feature modules.
