# Abstract Classes Should Set Log Group

## Intent

Ensure that all abstract classes using `LogMixin` have a defined log group for
consistent logging.

## Rule

Abstract classes that mix in `LogMixin` must set the log group to their class
name. If they extend another abstract class that also mixes in `LogMixin`, they
must override the log group to `"<super.group>.<subclass name>"`.

## Rationale

Setting a specific log group for each abstract class helps identify the source
of log messages. This is especially important in complex systems where multiple
abstract classes may be involved.

## Examples

```dart
// BAD: abstract class does not set log group
abstract class MyAbstractClass with LogMixin {
  // class implementation
}
```

```dart
// BAD: abstract class extends another abstract class but does not override log group
abstract class BaseAbstractClass with LogMixin {
  @override
  String get group => 'BaseAbstractClass';
}

abstract class DerivedAbstractClass extends BaseAbstractClass {
  // class implementation
}
```

```dart
// GOOD: abstract class sets log group to its class name
abstract class MyAbstractClass with LogMixin {
  @override
  String get group => 'MyAbstractClass';
}
```

```dart
// GOOD: abstract class extends another abstract class and overrides log group
abstract class BaseAbstractClass with LogMixin {
  @override
  String get group => 'BaseAbstractClass';
}

abstract class DerivedAbstractClass extends BaseAbstractClass {
  @override
  String get group => '${super.group}.DerivedAbstractClass';
}
```
