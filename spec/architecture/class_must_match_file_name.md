Class names should match the file names they are defined in (e.g., class FooBar should be defined in foo_bar.dart). This rule should only apply to module files.

If there is a class with a name that does match, any other classes do not need to match the file name.
For example, in a file named foo_bar.dart, the following is allowed:

```dart
class FooBar {}

class Baz {}
```

```dart
// BAD: class name does not match file name
// File: lib/src/rules/my_rule.dart
class AnotherRule {}
```
