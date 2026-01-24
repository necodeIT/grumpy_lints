
## Intent

Ensure that all concrete classes using the LogMixin have a defined log tag for consistent logging.

## Rule

A non abstract class that mixes in LogMixin must set the log tag to its class name. If it extends a superclass that also mixes in LogMixin, it must override the log tag to its own class name.

## Rationale

Setting a specific log tag for each concrete class helps in identifying the source of log messages. This is especially important in complex systems where multiple classes may be involved. By following this rule, developers can easily trace logs back to their origin, facilitating debugging and monitoring.

## Examples

```dart
// BAD: Concrete class does not set log tag
class MyConcreteClass with LogMixin {
  // class implementation
}
```

```dart
// GOOD: Concrete class sets log tag to its class name
class MyConcreteClass with LogMixin {
  @override
  String get logTag => 'MyConcreteClass';
}
```

```dart
// BAD: Concrete class with superclass that mixes in LogMixin but does not set log tag
abstract class BaseClass with LogMixin {
  // class implementation

    @override
    String get group => 'BaseClass';
}

class DerivedConcreteClass extends BaseClass {
  // class implementation
}
```

```dart
// GOOD: Concrete class with superclass that mixes in LogMixin and sets log tag
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

This rule applies only to non abstract classes. Abstract classes should follow the guidelines specified in [abstract_classes_should_set_log_group](abstract_classes_should_set_log_group.md) specification.
