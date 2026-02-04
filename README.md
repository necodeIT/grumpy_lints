# Grumpy Lints

Lint rules for using [Grumpy](https://github.com/necodeIT/grumpy) architecture correctly.

## Rules

| Rule | Overview | Severity | Fix Available | Codes |
| --- | --- | --- | --- | --- |
| [must_call_in_constructor](#must_call_in_constructor) | Require constructors to call methods annotated with @mustCallInConstructor on supertypes or mixins. | ERROR | ✅ | 3 |
| [abstract_classes_should_set_log_group](#abstract_classes_should_set_log_group) | Abstract classes using LogMixin must override group with their class name, or append to super.group. | ERROR | ✅ | 1 |
| [concrete_classes_should_set_log_tag](#concrete_classes_should_set_log_tag) | Concrete classes using LogMixin must override logTag with their class name. | ERROR | ✅ | 1 |
| [base_class](#base_class) | Subclasses of classes annotated with BaseClass must follow layer, naming, and file layout rules. | WARNING | ❌ | 6 |



### must_call_in_constructor

Require constructors to call methods annotated with @mustCallInConstructor on supertypes or mixins.
#### Codes
- `missing_required_constructor_call` (ERROR)
- `avoid_abstract_constructor_calls` (ERROR)
- `avoid_exempt_constructor_calls` (ERROR)

#### Examples
No examples provided.




### abstract_classes_should_set_log_group

Abstract classes using LogMixin must override group with their class name, or append to super.group.
#### Codes
- `abstract_classes_should_set_log_group` (ERROR)

#### Examples
**❌ DON'T**
```dart
abstract class MyAbstractClass with LogMixin {
}

```

**✅ DO**
```dart
abstract class MyAbstractClass with LogMixin {
  @override
  String get group => 'MyAbstractClass';
}

```

**✅ DO**
```dart
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

Concrete classes using LogMixin must override logTag with their class name.
#### Codes
- `concrete_classes_should_set_log_tag` (ERROR)

#### Examples
**❌ DON'T**
```dart
class MyConcreteClass with LogMixin {
}

```

**✅ DO**
```dart
class MyConcreteClass with LogMixin {
  @override
  String get logTag => 'MyConcreteClass';
}

```




### base_class

Subclasses of classes annotated with BaseClass must follow layer, naming, and file layout rules.
#### Codes
- `base_class_invalid_layer` (WARNING)
- `base_class_missing_suffix` (WARNING)
- `base_class_wrong_directory` (WARNING)
- `base_class_wrong_file_name` (WARNING)
- `base_class_extra_class` (WARNING)
- `base_class_missing_extension` (WARNING)

#### Examples
**✅ DO**
```dart
abstract class UserService extends Service {}

```

**❌ DON'T**
```dart
abstract class UserManager extends Service {}

```

