# Class Must Match File Name

## Intent

Ensure module file names remain a reliable signal for the primary class they
contain.

## Rule

Class names should match the file names they are defined in (for example,
class `FooBar` should be defined in `foo_bar.dart`). This rule applies only to
module files.

If there is a class with a name that matches, any other classes do not need to
match the file name.

## Rationale

Matching file names simplify discovery and reduce time spent searching for a
class definition.

## Examples

```dart
// GOOD: primary class matches file name
// File: lib/src/module/domain/foo_bar.dart
class FooBar {}

class Baz {}
```

```dart
// BAD: class name does not match file name
// File: lib/src/rules/my_rule.dart
class AnotherRule {}
```
