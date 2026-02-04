# Grumpy Lints

Lint rules for using [Grumpy](https://github.com/necodeIT/grumpy) architecture correctly.

## Rules

| Rule | Overview | Severity | Fix Available | Codes |
| --- | --- | --- | --- | --- |
| [must_call_in_constructor](#must_call_in_constructor) | Requires constructors to call methods annotated with @mustCallInConstructor from supertypes or mixins. It respects concreteOnly (abstract classes must not call those methods) and exempt (subtypes listed as exempt must not call the method at all). | ERROR | ✅ | 6 |
| [abstract_classes_should_set_log_group](#abstract_classes_should_set_log_group) | Abstract classes that mix in LogMixin must override `group` to return their class name. If they extend another abstract LogMixin class, they must append their class name to `super.group` to keep group names hierarchical. | INFO | ✅ | 1 |
| [concrete_classes_should_set_log_tag](#concrete_classes_should_set_log_tag) | Concrete (non-abstract) classes that mix in LogMixin must override `logTag` to return their own class name. This applies even when inheriting from another LogMixin class so each class logs with a specific tag. | INFO | ✅ | 1 |
| [base_class](#base_class) | Enforces the BaseClass contract: subclasses must live in allowed layers, use the base class name as a suffix when forceSuffix is true, reside in the configured type directory with a snake_case filename, be the only class in the file, and any class inside the type directory must extend the base class. Test files are exempt. | INFO | ❌ | 6 |



### must_call_in_constructor

Requires constructors to call methods annotated with @mustCallInConstructor from supertypes or mixins. It respects concreteOnly (abstract classes must not call those methods) and exempt (subtypes listed as exempt must not call the method at all).
#### Codes
- `missing_required_constructor_call` (ERROR)
- `missing_required_initializer_call` (ERROR)
- `avoid_abstract_constructor_calls` (ERROR)
- `avoid_abstract_initializer_calls` (ERROR)
- `avoid_exempt_constructor_calls` (INFO)
- `avoid_exempt_initializer_calls` (INFO)

#### Examples
**❌ DON'T**
```dart
// Missing required call in the constructor.
mixin InitMixin {
  @mustCallInConstructor
  void init() {}
}

class Widget with InitMixin {
  Widget();
}

```

**✅ DO**
```dart
// Required call is present.
mixin InitMixin {
  @mustCallInConstructor
  void init() {}
}

class Widget with InitMixin {
  Widget() {
    init();
  }
}

```

**❌ DON'T**
```dart
// Abstract classes must not call methods that are concreteOnly.
mixin InitMixin {
  @MustCallInConstructor(concreteOnly: true)
  void init() {}
}

abstract class BaseWidget with InitMixin {
  BaseWidget() {
    init();
  }
}

```

**❌ DON'T**
```dart
// Exempt types must not call the annotated method.
mixin InitMixin {
  @MustCallInConstructor(exempt: [NoopWidget])
  void init() {}
}

class NoopWidget with InitMixin {
  NoopWidget() {
    init();
  }
}

```

**✅ DO**
```dart
// Exempt types can omit the call entirely.
mixin InitMixin {
  @MustCallInConstructor(exempt: [NoopWidget])
  void init() {}
}

class NoopWidget with InitMixin {
  NoopWidget();
}

```




### abstract_classes_should_set_log_group

Abstract classes that mix in LogMixin must override `group` to return their class name. If they extend another abstract LogMixin class, they must append their class name to `super.group` to keep group names hierarchical.
#### Codes
- `abstract_classes_should_set_log_group` (INFO)

#### Examples
**❌ DON'T**
```dart
// Missing group override on an abstract LogMixin class.
abstract class MyAbstractClass with LogMixin {
  // ...
}

```

**❌ DON'T**
```dart
// Missing group override when extending another LogMixin class.
abstract class BaseAbstractClass with LogMixin {
  @override
  String get group => 'BaseAbstractClass';
}

abstract class DerivedAbstractClass extends BaseAbstractClass {
  // ...
}

```

**✅ DO**
```dart
// Group must match the abstract class name.
abstract class MyAbstractClass with LogMixin {
  @override
  String get group => 'MyAbstractClass';
}

```

**✅ DO**
```dart
// Derived abstract classes must append to super.group.
abstract class BaseAbstractClass with LogMixin {
  @override
  String get group => 'BaseAbstractClass';
}

abstract class DerivedAbstractClass extends BaseAbstractClass {
  @override
  String get group => '${super.group}.DerivedAbstractClass';
}

```




### concrete_classes_should_set_log_tag

Concrete (non-abstract) classes that mix in LogMixin must override `logTag` to return their own class name. This applies even when inheriting from another LogMixin class so each class logs with a specific tag.
#### Codes
- `concrete_classes_should_set_log_tag` (INFO)

#### Examples
**❌ DON'T**
```dart
// Missing logTag override on a concrete LogMixin class.
class MyConcreteClass with LogMixin {
  // ...
}

```

**✅ DO**
```dart
// Concrete class must use its own class name as logTag.
class MyConcreteClass with LogMixin {
  @override
  String get logTag => 'MyConcreteClass';
}

```

**❌ DON'T**
```dart
// Missing logTag override when extending another LogMixin class.
abstract class BaseClass with LogMixin {
  @override
  String get group => 'BaseClass';
}

class DerivedConcreteClass extends BaseClass {
  // ...
}

```

**✅ DO**
```dart
// Derived concrete classes must override logTag too.
abstract class BaseClass with LogMixin {
  @override
  String get group => 'BaseClass';
}

class DerivedConcreteClass extends BaseClass {
  @override
  String get logTag => 'DerivedConcreteClass';
}

```




### base_class

Enforces the BaseClass contract: subclasses must live in allowed layers, use the base class name as a suffix when forceSuffix is true, reside in the configured type directory with a snake_case filename, be the only class in the file, and any class inside the type directory must extend the base class. Test files are exempt.
#### Codes
- `base_class_invalid_layer` (INFO)
- `base_class_missing_suffix` (INFO)
- `base_class_wrong_directory` (INFO)
- `base_class_wrong_file_name` (INFO)
- `base_class_extra_class` (INFO)
- `base_class_missing_extension` (INFO)

#### Examples
**✅ DO**
```dart
// Base class:
@BaseClass(allowedLayers: {LayerType.domain}, typeDirectory: 'services')
abstract class Service {}

// File: lib/src/module/domain/services/user_service.dart
abstract class UserService extends Service {}

```

**❌ DON'T**
```dart
// Wrong layer (presentation is not allowed).
// File: lib/src/module/presentation/services/user_service.dart
abstract class UserService extends Service {}

```

**❌ DON'T**
```dart
// Missing suffix when forceSuffix is true.
// File: lib/src/module/domain/services/user_manager.dart
abstract class UserManager extends Service {}

```

**❌ DON'T**
```dart
// Wrong directory (should be services/).
// File: lib/src/module/domain/user_service.dart
abstract class UserService extends Service {}

```

**❌ DON'T**
```dart
// Wrong file name (should be user_service.dart).
// File: lib/src/module/domain/services/userService.dart
abstract class UserService extends Service {}

```

**❌ DON'T**
```dart
// Extra class in the same file.
// File: lib/src/module/domain/services/user_service.dart
abstract class UserService extends Service {}

class Helper {}

```

**❌ DON'T**
```dart
// Class in the services/ directory must extend Service.
// File: lib/src/module/domain/services/user_service.dart
abstract class UserService {}

```

