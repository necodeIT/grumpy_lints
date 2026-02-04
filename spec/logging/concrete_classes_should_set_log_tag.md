# Concrete Classes Should Set Log Tag

## Intent

Ensure that all concrete classes using `LogMixin` have a defined log tag for
consistent logging.

## Rule

A non-abstract class that mixes in `LogMixin` must set the log tag to its class
name. If it extends a superclass that also mixes in `LogMixin`, it must
override the log tag to its own class name.

## Rationale

Setting a specific log tag for each concrete class helps identify the source of
log messages. This is especially important in complex systems where multiple
classes may be involved.

## Examples

```dart
// BAD: concrete class does not set log tag
class MyConcreteClass with LogMixin {
  // class implementation
}
```

```dart
// GOOD: concrete class sets log tag to its class name
class MyConcreteClass with LogMixin {
  @override
  String get logTag => 'MyConcreteClass';
}
```

```dart
// BAD: concrete class with superclass that mixes in LogMixin but does not set log tag
abstract class BaseClass with LogMixin {
  @override
  String get group => 'BaseClass';
}

class DerivedConcreteClass extends BaseClass {
  // class implementation
}
```

```dart
// GOOD: concrete class with superclass that mixes in LogMixin and sets log tag
abstract class BaseClass with LogMixin {
  @override
  String get group => 'BaseClass';
}

class DerivedConcreteClass extends BaseClass {
  @override
  String get logTag => 'DerivedConcreteClass';
}
```

## Notes

This rule applies only to non-abstract classes. Abstract classes should follow
[abstract_classes_should_set_log_group](abstract_classes_should_set_log_group.md).
