
## Intent

Ensure that all abstract classes using the LogMixin have a defined log group for consistent logging.

## Rule

Abstract classes that mix in LogMixin must set the log group to their class name. If they extend another abstract class that also mixes in LogMixin, they must override the log group to "<super.group>.<subclass name>".

## Rationale

Setting a specific log group for each abstract class helps in identifying the source of log messages. This is especially important in complex systems where multiple abstract classes may be involved. By following this rule, developers can easily trace logs back to their origin, facilitating debugging and monitoring.

## Examples

```dart
// BAD: Abstract class does not set log group
abstract class MyAbstractClass with LogMixin {
  // class implementation
}

```

```dart
// BAD: Abstract class extends another abstract class but does not override log group
abstract class BaseAbstractClass with LogMixin {
  @override
  String get group => 'BaseAbstractClass';
}

abstract class DerivedAbstractClass extends BaseAbstractClass {
  // class implementation
}
```

```dart
// GOOD: Abstract class sets log group to its class name
abstract class MyAbstractClass with LogMixin {
  @override
  String get group => 'MyAbstractClass';
}
```

```dart
// GOOD: Abstract class extends another abstract class and overrides log group
abstract class BaseAbstractClass with LogMixin {
  @override
  String get group => 'BaseAbstractClass';
}

abstract class DerivedAbstractClass extends BaseAbstractClass {
  @override
  String get group => '${super.group}.DerivedAbstractClass';
}
```
