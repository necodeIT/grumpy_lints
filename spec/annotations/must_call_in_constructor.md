# Must Call In Constructor

## Intent

Ensure required initialization hooks are invoked at the right lifecycle entrypoint.

## Rule

If a class mixes in or extends a type that declares methods annotated with
`@MustCallInConstructor`, those methods must be invoked.

- Default: the required calls must occur in the constructor.
- If the class declares a method annotated with `@initializer`, the required
  calls must occur in an initializer method instead of the constructor.

If `concreteOnly` is true, only non-abstract classes are required to make the
call. If the class is a subtype of any type listed in the `exempt` parameter,
then it must not call the method at all.

## Rationale

Some frameworks (for example Flutter `State.initState`) require initialization
outside the constructor. The `@initializer` annotation lets a class opt into a
specific initialization entrypoint while keeping the requirement enforced.

## Examples

```dart
// BAD: Missing required call in constructor.
mixin InitMixin {
  @MustCallInConstructor()
  void init() {}
}

class Widget with InitMixin {
  Widget();
}
```

```dart
// GOOD: Required call present in constructor.
mixin InitMixin {
  @MustCallInConstructor()
  void init() {}
}

class Widget with InitMixin {
  Widget() {
    init();
  }
}
```

```dart
// BAD: Class has initializer, but required call is not inside it.
mixin InitMixin {
  @MustCallInConstructor()
  void init() {}
}

class Widget with InitMixin {
  @initializer
  void initState() {}
}
```

```dart
// GOOD: Required call appears in initializer.
mixin InitMixin {
  @MustCallInConstructor()
  void init() {}
}

class Widget with InitMixin {
  @initializer
  void initState() {
    init();
  }
}
```

```dart
// BAD: Abstract classes must not call concreteOnly hooks.
mixin InitMixin {
  @MustCallInConstructor(concreteOnly: true)
  void init() {}
}

abstract class BaseWidget with InitMixin {
  @initializer
  void initState() {
    init();
  }
}
```

```dart
// BAD: Exempt types must not call the hook.
mixin InitMixin {
  @MustCallInConstructor(exempt: [NoopWidget])
  void init() {}
}

class NoopWidget with InitMixin {
  @initializer
  void initState() {
    init();
  }
}
```

```dart
// GOOD: Exempt types can omit the call.
mixin InitMixin {
  @MustCallInConstructor(exempt: [NoopWidget])
  void init() {}
}

class NoopWidget with InitMixin {
  @initializer
  void initState() {}
}
```

## Notes

- If any initializer method exists, required calls must happen in an
  initializer, even if the constructor also calls them.
- Required calls made in a superclass initializer satisfy subclasses.
