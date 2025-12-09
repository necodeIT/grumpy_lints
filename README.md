# Modular Foundation Lints

Lint rules for using Modular Foundation.

## Rules

| Rule | Overview | Severity | Enabled by Default | Fix Available |
| ---- | -------- | -------- | ------------------ | ------------- |
| [call_initialize_in_constructor](#call_initialize_in_constructor) | A constructor of class with LifecycleMixin must call `initialize`. | ERROR | Yes | ✅ |
| [avoid_abstract_initialize_calls](#avoid_abstract_initialize_calls) | An abstract class constructor must not call `initialize` since it cannot be instantiated. | ERROR | Yes | ✅ |
| [call_initialize_last](#call_initialize_last) | `initialize` should be called at the end of the constructor body. | WARNING | Yes | ✅ |
| [constructor_must_call_install_hooks](#constructor_must_call_install_hooks) | A constructor of class with LifecycleMixin must call installHooks() at the **beginning** of its body. | ERROR | Yes | ✅ |
| [services_must_have_service_suffix](#services_must_have_service_suffix) | A services declaration must have a name that ends with "Service" to ensure proper identification within the modular framework. | WARNING | Yes | ✅ |
| [datasources_must_have_datasource_suffix](#datasources_must_have_datasource_suffix) | A datasources declaration must have a name that ends with "Datasource" to ensure proper identification within the modular framework. | WARNING | Yes | ✅ |
| [models_must_have_model_suffix](#models_must_have_model_suffix) | A models declaration must have a name that ends with "Model" to ensure proper identification within the modular framework. | WARNING | No | ✅ |
| [repositories_must_have_repo_suffix](#repositories_must_have_repo_suffix) | A repositories declaration must have a name that ends with "Repo" to ensure proper identification within the modular framework. | WARNING | Yes | ✅ |
| [views_must_have_view_suffix](#views_must_have_view_suffix) | A views declaration must have a name that ends with "View" to ensure proper identification within the modular framework. | WARNING | Yes | ✅ |
| [guards_must_have_guard_suffix](#guards_must_have_guard_suffix) | A guards declaration must have a name that ends with "Guard" to ensure proper identification within the modular framework. | WARNING | Yes | ✅ |
| [services_must_extend_service](#services_must_extend_service) | A service declaration in services must extend the base Service class to ensure proper functionality within the modular framework. | ERROR | Yes | ✅ |
| [datasources_must_extend_datasource](#datasources_must_extend_datasource) | A datasource declaration in datasources must extend the base Datasource class to ensure proper functionality within the modular framework. | ERROR | Yes | ✅ |
| [models_must_extend_model](#models_must_extend_model) | A model declaration in models must extend the base Model class to ensure proper functionality within the modular framework. | ERROR | Yes | ✅ |
| [repositories_must_extend_repo](#repositories_must_extend_repo) | A repo declaration in repositories must extend the base Repo class to ensure proper functionality within the modular framework. | ERROR | Yes | ✅ |
| [views_must_extend_view](#views_must_extend_view) | A view declaration in views must extend the base View class to ensure proper functionality within the modular framework. | ERROR | Yes | ✅ |
| [guards_must_extend_guard](#guards_must_extend_guard) | A guard declaration in guards must extend the base Guard class to ensure proper functionality within the modular framework. | ERROR | Yes | ✅ |



### call_initialize_in_constructor

No additional details provided.
#### Examples
No examples provided.




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

No additional details provided.
#### Examples
No examples provided.




### constructor_must_call_install_hooks

No additional details provided.
#### Examples
No examples provided.




### services_must_have_service_suffix

A services class must have a name that ends with "Service" to ensure proper identification within the modular framework.
#### Examples
**✅ DO**
```dart
abstract class MyCustomService extends Service {
  // Service implementation
}

```

**❌ DON'T**
```dart
abstract class MyCustom {
  // Service implementation
}

```




### datasources_must_have_datasource_suffix

A datasources class must have a name that ends with "Datasource" to ensure proper identification within the modular framework.
#### Examples
**✅ DO**
```dart
abstract class MyCustomDatasource extends Datasource {
  // Service implementation
}

```

**❌ DON'T**
```dart
abstract class MyCustom {
  // Service implementation
}

```




### models_must_have_model_suffix

A models class must have a name that ends with "Model" to ensure proper identification within the modular framework.
#### Examples
**✅ DO**
```dart
abstract class MyCustomModel extends Model {
  // Service implementation
}

```

**❌ DON'T**
```dart
abstract class MyCustom {
  // Service implementation
}

```




### repositories_must_have_repo_suffix

A repositories class must have a name that ends with "Repo" to ensure proper identification within the modular framework.
#### Examples
**✅ DO**
```dart
abstract class MyCustomRepo extends Repo {
  // Service implementation
}

```

**❌ DON'T**
```dart
abstract class MyCustom {
  // Service implementation
}

```




### views_must_have_view_suffix

A views class must have a name that ends with "View" to ensure proper identification within the modular framework.
#### Examples
**✅ DO**
```dart
abstract class MyCustomView extends View {
  // Service implementation
}

```

**❌ DON'T**
```dart
abstract class MyCustom {
  // Service implementation
}

```




### guards_must_have_guard_suffix

A guards class must have a name that ends with "Guard" to ensure proper identification within the modular framework.
#### Examples
**✅ DO**
```dart
abstract class MyCustomGuard extends Guard {
  // Service implementation
}

```

**❌ DON'T**
```dart
abstract class MyCustom {
  // Service implementation
}

```




### services_must_extend_service

A service class must extend the base `Service` class provided by the modular framework. This ensures that the service integrates properly with the framework's lifecycle management, dependency injection, and other core functionalities.
#### Examples
**✅ DO**
```dart
abstract class MyService extends Service {
  // service implementation
}

```

**❌ DON'T**
```dart
abstract class MyService {
  // service implementation
}

```




### datasources_must_extend_datasource

A datasource class must extend the base `Datasource` class provided by the modular framework. This ensures that the datasource integrates properly with the framework's lifecycle management, dependency injection, and other core functionalities.
#### Examples
**✅ DO**
```dart
abstract class MyDatasource extends Datasource {
  // datasource implementation
}

```

**❌ DON'T**
```dart
abstract class MyDatasource {
  // datasource implementation
}

```




### models_must_extend_model

A model class must extend the base `Model` class provided by the modular framework. This ensures that the model integrates properly with the framework's lifecycle management, dependency injection, and other core functionalities.
#### Examples
**✅ DO**
```dart
abstract class MyModel extends Model {
  // model implementation
}

```

**❌ DON'T**
```dart
abstract class MyModel {
  // model implementation
}

```




### repositories_must_extend_repo

A repo class must extend the base `Repo` class provided by the modular framework. This ensures that the repo integrates properly with the framework's lifecycle management, dependency injection, and other core functionalities.
#### Examples
**✅ DO**
```dart
abstract class MyRepo extends Repo {
  // repo implementation
}

```

**❌ DON'T**
```dart
abstract class MyRepo {
  // repo implementation
}

```




### views_must_extend_view

A view class must extend the base `View` class provided by the modular framework. This ensures that the view integrates properly with the framework's lifecycle management, dependency injection, and other core functionalities.
#### Examples
**✅ DO**
```dart
abstract class MyView extends View {
  // view implementation
}

```

**❌ DON'T**
```dart
abstract class MyView {
  // view implementation
}

```




### guards_must_extend_guard

A guard class must extend the base `Guard` class provided by the modular framework. This ensures that the guard integrates properly with the framework's lifecycle management, dependency injection, and other core functionalities.
#### Examples
**✅ DO**
```dart
abstract class MyGuard extends Guard {
  // guard implementation
}

```

**❌ DON'T**
```dart
abstract class MyGuard {
  // guard implementation
}

```

