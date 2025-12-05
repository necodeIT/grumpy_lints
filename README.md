# Modular Foundation Lints

Lint rules for using Modular Foundation.

## Rules

| Rule | Overview | Severity | Enabled by Default | Fix Available |
| ---- | -------- | -------- | ------------------ | ------------- |
| [call_initialize_in_constructor](#call_initialize_in_constructor) | A constructor of class with LifecycleMixin must call `initialize`. | ERROR | Yes | ✅ |
| [avoid_abstract_initialize_calls](#avoid_abstract_initialize_calls) | An abstract class constructor must not call `initialize` since it cannot be instantiated. | ERROR | Yes | ✅ |
| [call_initialize_last](#call_initialize_last) | `initialize` should be called at the end of the constructor body. | WARNING | Yes | ✅ |
| [constructor_must_call_install_hooks](#constructor_must_call_install_hooks) | A constructor of class with LifecycleMixin must call installHooks() at the **beginning** of its body. | ERROR | Yes | ✅ |

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
