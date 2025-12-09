# Modular Foundation Lints

Lint rules for using Modular Foundation.

## Rules

| Rule | Overview | Severity | Enabled by Default | Fix Available |
| ---- | -------- | -------- | ------------------ | ------------- |
| [call_initialize_in_constructor](#call_initialize_in_constructor) | A constructor of class with LifecycleMixin must call `initialize`. | ERROR | Yes | ✅ |
| [avoid_abstract_initialize_calls](#avoid_abstract_initialize_calls) | An abstract class constructor must not call `initialize` since it cannot be instantiated. | ERROR | Yes | ✅ |
| [call_initialize_last](#call_initialize_last) | `initialize` should be called at the end of the constructor body. | WARNING | Yes | ✅ |
| [constructor_must_call_install_hooks](#constructor_must_call_install_hooks) | A constructor of a class with required hook mixins must call their installer methods. | ERROR | Yes | ✅ |
| [services_must_have_service_suffix](#services_must_have_service_suffix) | Classes in the "services" layer must have names that end with "Service" to follow the naming convention. | WARNING | Yes | ✅ |
| [datasources_must_have_datasource_suffix](#datasources_must_have_datasource_suffix) | Classes in the "datasources" layer must have names that end with "Datasource" to follow the naming convention. | WARNING | Yes | ✅ |
| [models_must_have_model_suffix](#models_must_have_model_suffix) | Classes in the "models" layer must have names that end with "Model" to follow the naming convention. | WARNING | No | ✅ |
| [repositories_must_have_repo_suffix](#repositories_must_have_repo_suffix) | Classes in the "repositories" layer must have names that end with "Repo" to follow the naming convention. | WARNING | Yes | ✅ |
| [views_must_have_view_suffix](#views_must_have_view_suffix) | Classes in the "views" layer must have names that end with "View" to follow the naming convention. | WARNING | Yes | ✅ |
| [guards_must_have_guard_suffix](#guards_must_have_guard_suffix) | Classes in the "guards" layer must have names that end with "Guard" to follow the naming convention. | WARNING | Yes | ✅ |
| [services_must_extend_service](#services_must_extend_service) | Classes in the "services" layer must extend Service so the modular framework can treat them uniformly. | ERROR | Yes | ✅ |
| [datasources_must_extend_datasource](#datasources_must_extend_datasource) | Classes in the "datasources" layer must extend Datasource so the modular framework can treat them uniformly. | ERROR | Yes | ✅ |
| [models_must_extend_model](#models_must_extend_model) | Classes in the "models" layer must extend Model so the modular framework can treat them uniformly. | ERROR | Yes | ✅ |
| [repositories_must_extend_repo](#repositories_must_extend_repo) | Classes in the "repositories" layer must extend Repo so the modular framework can treat them uniformly. | ERROR | Yes | ✅ |
| [views_must_extend_view](#views_must_extend_view) | Classes in the "views" layer must extend View so the modular framework can treat them uniformly. | ERROR | Yes | ✅ |
| [guards_must_extend_guard](#guards_must_extend_guard) | Classes in the "guards" layer must extend Guard so the modular framework can treat them uniformly. | ERROR | Yes | ✅ |



### call_initialize_in_constructor

Enforces that every non-abstract class using `LifecycleMixin` calls `initialize()` in its constructor body.

Concrete types with `LifecycleMixin` are expected to trigger their lifecycle hooks (such as `onInitialize`) when an instance is created. If `initialize()` is never called, those hooks will silently never run, leading to partially-initialized objects and hard-to-track bugs.

This rule complements `avoid_abstract_initialize_calls`:
- abstract base classes **must not** call `initialize()` in their constructors
- concrete subclasses **must** call `initialize()` in theirs.

#### Examples
**✅ DO**
```dart
// ✅ Correct: concrete class with LifecycleMixin calls initialize().
class MyService with LifecycleMixin {
  MyService() {
    // Custom setup...
    initialize();
  }
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: initialize() is never called in the constructor.
class MyService with LifecycleMixin {
  MyService() {
    // Custom setup...
  }
}

```

**✅ DO**
```dart
// ✅ Correct: all non-factory constructors call initialize().
class MultiCtorService with LifecycleMixin {
  MultiCtorService() {
    initialize();
  }

  MultiCtorService.withConfig(Config config) {
    // Use config...
    initialize();
  }
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: one of the constructors forgets to call initialize().
class MultiCtorService with LifecycleMixin {
  MultiCtorService() {
    initialize();
  }

  MultiCtorService.withConfig(Config config) {
    // Use config...
    // Missing initialize();
  }
}

```




### avoid_abstract_initialize_calls

Abstract classes with a LifecycleMixin should not call `initialize()` in their constructors, as abstract classes cannot be instantiated. Calling `initialize()` in an abstract class will fire the onInitialize lifecycle event prematurely, potentially leading to unexpected behavior.

Instead, `initialize()` should be called in the constructors of concrete subclasses that extend the abstract class. This ensures that the lifecycle events are triggered appropriately when instances of the concrete classes are created.

#### Examples
**✅ DO**
```dart
class MyConcreteClass extends MyBaseClass {
  MyConcreteClass() : super() {
    // Correct: Calling initialize in a concrete class
    initialize();
  }
}

```

**❌ DON'T**
```dart
abstract class MyBaseClass with LifecycleMixin {
  MyBaseClass() {
    // Incorrect: Calling initialize in an abstract class
    initialize();
  }
}

```




### call_initialize_last

Enforces that `initialize()` is the *last* statement in the constructor body of concrete classes using `LifecycleMixin`.

`initialize()` typically triggers lifecycle callbacks (such as `onInitialize`). If you keep doing work after that call — mutating fields, registering listeners, emitting events — that logic runs **after** the lifecycle phase, and consumers may see a half-initialized object.

By always calling `initialize()` last, you ensure that:

- all constructor setup runs before lifecycle hooks observe the instance
- there is a clear, predictable "end of initialization" point
- side-effects after construction are not accidentally executed during initialization.

#### Examples
**✅ DO**
```dart
// ✅ Correct: initialize() is called last.
class MyService with LifecycleMixin {
  MyService(Dependency dep) {
    _dep = dep;
    _configure();
    initialize();
  }

  late final Dependency _dep;

  void _configure() {
    // setup...
  }
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: work happens after initialize().
class MyService with LifecycleMixin {
  MyService(Dependency dep) {
    _dep = dep;
    initialize(); // Lifecycle hooks run here...

    _configure(); // ...but more setup happens afterwards.
  }

  late final Dependency _dep;

  void _configure() {
    // setup...
  }
}

```

**✅ DO**
```dart
// ✅ Correct: guard logic + branching before initialize(), nothing after.
class ConditionalService with LifecycleMixin {
  ConditionalService(bool enabled) {
    if (!enabled) {
      _disabled = true;
      initialize();
      return;
    }

    _disabled = false;
    _prepareHeavyResources();
    initialize();
  }

  bool _disabled = false;

  void _prepareHeavyResources() {}
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: logic after initialize() in some branches.
class ConditionalService with LifecycleMixin {
  ConditionalService(bool enabled) {
    if (!enabled) {
      _disabled = true;
      initialize();
      return;
    }

    _disabled = false;
    initialize(); // Called too early.
    _prepareHeavyResources(); // Runs after lifecycle hooks.
  }

  bool _disabled = false;

  void _prepareHeavyResources() {}
}

```




### constructor_must_call_install_hooks

Ensures that any concrete class using mixins which expose installer-style hook methods (for example, `installLoggingHooks`, `installLifecycleHooks`) actually calls those methods from its constructor.

This rule scans mixins for methods named like `install*Hooks` (@mustCallInConstructor in the future). If a class mixes in such a mixin (directly or via a superclass), each `install*Hooks` method is treated as **required** at construction time. Missing installer calls usually mean hooks/listeners/telemetry are never wired up, even though the type advertises that behaviour via its mixins.

The fix inserts the missing `install*Hooks()` calls at the beginning of the constructor body.

#### Examples
**✅ DO**
```dart
// ✅ Correct: constructor calls the installer from the mixin.
mixin LoggingHooks {
  @mustCallInConstructor
  void installLoggingHooks() {
    // set up loggers, sinks, etc.
  }
}

class UserService with LoggingHooks {
  UserService() {
    installLoggingHooks();
    // other setup...
  }
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: mixin is used, but its installer is never called.
mixin LoggingHooks { 
  @mustCallInConstructor
  void installLoggingHooks() {
    // set up loggers, sinks, etc.
  }
}

class UserService with LoggingHooks {
  UserService() {
    // other setup...
    // Missing: installLoggingHooks();
  }
}

```

**✅ DO**
```dart
// ✅ Correct: subclass still calls installers from a mixin on the base class.
mixin MetricsHooks {
  @mustCallInConstructor
  void installMetricsHooks() {}
}

abstract class BaseService with MetricsHooks {
  BaseService();
}

class OrdersService extends BaseService {
  OrdersService() : super() {
    installMetricsHooks();
  }
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: subclass relies on mixin from superclass but forgets installer.
mixin MetricsHooks {
  @mustCallInConstructor
  void installMetricsHooks() {}
}

abstract class BaseService with MetricsHooks {
  BaseService();
}

class OrdersService extends BaseService {
  OrdersService() : super() {
    // Missing: installMetricsHooks();
  }
}

```




### services_must_have_service_suffix

Enforces a naming convention for the `services` layer: all classes must end with the `Service` suffix.

This keeps responsibilities easy to spot (by name alone), improves search/filters in large codebases, and makes the modular architecture predictable.
#### Examples
**✅ DO**
```dart
// ✅ Correct: class name follows the "Service" convention.
abstract class UserAccountService {
  // services implementation
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: missing the required "Service" suffix.
abstract class UserAccount {
  // services implementation
}

```

**✅ DO**
```dart
// ✅ Correct: concrete class also uses the "Service" suffix.
class PaymentProcessingService {
  // ...
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: same concept without the "Service" suffix.
class PaymentProcessing {
  // ...
}

```




### datasources_must_have_datasource_suffix

Enforces a naming convention for the `datasources` layer: all classes must end with the `Datasource` suffix.

This keeps responsibilities easy to spot (by name alone), improves search/filters in large codebases, and makes the modular architecture predictable.
#### Examples
**✅ DO**
```dart
// ✅ Correct: class name follows the "Datasource" convention.
abstract class UserAccountDatasource {
  // datasources implementation
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: missing the required "Datasource" suffix.
abstract class UserAccount {
  // datasources implementation
}

```

**✅ DO**
```dart
// ✅ Correct: concrete class also uses the "Datasource" suffix.
class PaymentProcessingDatasource {
  // ...
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: same concept without the "Datasource" suffix.
class PaymentProcessing {
  // ...
}

```




### models_must_have_model_suffix

Enforces a naming convention for the `models` layer: all classes must end with the `Model` suffix.

This keeps responsibilities easy to spot (by name alone), improves search/filters in large codebases, and makes the modular architecture predictable.
#### Examples
**✅ DO**
```dart
// ✅ Correct: class name follows the "Model" convention.
abstract class UserAccountModel {
  // models implementation
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: missing the required "Model" suffix.
abstract class UserAccount {
  // models implementation
}

```

**✅ DO**
```dart
// ✅ Correct: concrete class also uses the "Model" suffix.
class PaymentProcessingModel {
  // ...
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: same concept without the "Model" suffix.
class PaymentProcessing {
  // ...
}

```




### repositories_must_have_repo_suffix

Enforces a naming convention for the `repositories` layer: all classes must end with the `Repo` suffix.

This keeps responsibilities easy to spot (by name alone), improves search/filters in large codebases, and makes the modular architecture predictable.
#### Examples
**✅ DO**
```dart
// ✅ Correct: class name follows the "Repo" convention.
abstract class UserAccountRepo {
  // repositories implementation
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: missing the required "Repo" suffix.
abstract class UserAccount {
  // repositories implementation
}

```

**✅ DO**
```dart
// ✅ Correct: concrete class also uses the "Repo" suffix.
class PaymentProcessingRepo {
  // ...
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: same concept without the "Repo" suffix.
class PaymentProcessing {
  // ...
}

```




### views_must_have_view_suffix

Enforces a naming convention for the `views` layer: all classes must end with the `View` suffix.

This keeps responsibilities easy to spot (by name alone), improves search/filters in large codebases, and makes the modular architecture predictable.
#### Examples
**✅ DO**
```dart
// ✅ Correct: class name follows the "View" convention.
abstract class UserAccountView {
  // views implementation
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: missing the required "View" suffix.
abstract class UserAccount {
  // views implementation
}

```

**✅ DO**
```dart
// ✅ Correct: concrete class also uses the "View" suffix.
class PaymentProcessingView {
  // ...
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: same concept without the "View" suffix.
class PaymentProcessing {
  // ...
}

```




### guards_must_have_guard_suffix

Enforces a naming convention for the `guards` layer: all classes must end with the `Guard` suffix.

This keeps responsibilities easy to spot (by name alone), improves search/filters in large codebases, and makes the modular architecture predictable.
#### Examples
**✅ DO**
```dart
// ✅ Correct: class name follows the "Guard" convention.
abstract class UserAccountGuard {
  // guards implementation
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: missing the required "Guard" suffix.
abstract class UserAccount {
  // guards implementation
}

```

**✅ DO**
```dart
// ✅ Correct: concrete class also uses the "Guard" suffix.
class PaymentProcessingGuard {
  // ...
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: same concept without the "Guard" suffix.
class PaymentProcessing {
  // ...
}

```




### services_must_extend_service

Require all classes in the `services` layer to extend `Service`.

This ensures a consistent API for the modular framework (e.g. lifecycle hooks, logging, error handling) and prevents classes from silently opting out of the shared behaviour.
#### Examples
**✅ DO**
```dart
// ✅ Correct: extends the required base class.
abstract class MyService extends Service {
  // service implementation
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: does not extend the required base class.
abstract class MyService {
  // service implementation
}

```

**✅ DO**
```dart
// ✅ Correct: concrete class in the "services" layer extends the base type.
class UserProfileService extends Service {
  // ...
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: concrete class in the "services" layer without the base type.
class UserProfileService {
  // ...
}

```




### datasources_must_extend_datasource

Require all classes in the `datasources` layer to extend `Datasource`.

This ensures a consistent API for the modular framework (e.g. lifecycle hooks, logging, error handling) and prevents classes from silently opting out of the shared behaviour.
#### Examples
**✅ DO**
```dart
// ✅ Correct: extends the required base class.
abstract class MyDatasource extends Datasource {
  // datasource implementation
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: does not extend the required base class.
abstract class MyDatasource {
  // datasource implementation
}

```

**✅ DO**
```dart
// ✅ Correct: concrete class in the "datasources" layer extends the base type.
class UserProfileDatasource extends Datasource {
  // ...
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: concrete class in the "datasources" layer without the base type.
class UserProfileDatasource {
  // ...
}

```




### models_must_extend_model

Require all classes in the `models` layer to extend `Model`.

This ensures a consistent API for the modular framework (e.g. lifecycle hooks, logging, error handling) and prevents classes from silently opting out of the shared behaviour.
#### Examples
**✅ DO**
```dart
// ✅ Correct: extends the required base class.
abstract class MyModel extends Model {
  // model implementation
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: does not extend the required base class.
abstract class MyModel {
  // model implementation
}

```

**✅ DO**
```dart
// ✅ Correct: concrete class in the "models" layer extends the base type.
class UserProfileModel extends Model {
  // ...
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: concrete class in the "models" layer without the base type.
class UserProfileModel {
  // ...
}

```




### repositories_must_extend_repo

Require all classes in the `repositories` layer to extend `Repo`.

This ensures a consistent API for the modular framework (e.g. lifecycle hooks, logging, error handling) and prevents classes from silently opting out of the shared behaviour.
#### Examples
**✅ DO**
```dart
// ✅ Correct: extends the required base class.
abstract class MyRepo extends Repo {
  // repo implementation
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: does not extend the required base class.
abstract class MyRepo {
  // repo implementation
}

```

**✅ DO**
```dart
// ✅ Correct: concrete class in the "repositories" layer extends the base type.
class UserProfileRepo extends Repo {
  // ...
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: concrete class in the "repositories" layer without the base type.
class UserProfileRepo {
  // ...
}

```




### views_must_extend_view

Require all classes in the `views` layer to extend `View`.

This ensures a consistent API for the modular framework (e.g. lifecycle hooks, logging, error handling) and prevents classes from silently opting out of the shared behaviour.
#### Examples
**✅ DO**
```dart
// ✅ Correct: extends the required base class.
abstract class MyView extends View {
  // view implementation
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: does not extend the required base class.
abstract class MyView {
  // view implementation
}

```

**✅ DO**
```dart
// ✅ Correct: concrete class in the "views" layer extends the base type.
class UserProfileView extends View {
  // ...
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: concrete class in the "views" layer without the base type.
class UserProfileView {
  // ...
}

```




### guards_must_extend_guard

Require all classes in the `guards` layer to extend `Guard`.

This ensures a consistent API for the modular framework (e.g. lifecycle hooks, logging, error handling) and prevents classes from silently opting out of the shared behaviour.
#### Examples
**✅ DO**
```dart
// ✅ Correct: extends the required base class.
abstract class MyGuard extends Guard {
  // guard implementation
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: does not extend the required base class.
abstract class MyGuard {
  // guard implementation
}

```

**✅ DO**
```dart
// ✅ Correct: concrete class in the "guards" layer extends the base type.
class UserProfileGuard extends Guard {
  // ...
}

```

**❌ DON'T**
```dart
// ❌ Incorrect: concrete class in the "guards" layer without the base type.
class UserProfileGuard {
  // ...
}

```

