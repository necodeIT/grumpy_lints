# LifecycleMixin Injectables Must Be Singletons

## Intent

Ensure DI-managed lifecycle hooks are reliable by only allowing them on
singleton `Injectable` implementations.

## Rule

If a class implements `Injectable` and mixes in `LifecycleMixin`, it must
resolve as a singleton by returning `true` from `singelton`.

In other words, `Injectable` + `LifecycleMixin` must never evaluate to
`singelton == false`.

# Severity

Error

## Rationale

Module DI uses `Injectable.singelton` to choose between
`GetIt.registerLazySingleton` and `GetIt.registerFactory`.
Lifecycle callbacks depend on a stable instance. Factory-scoped lifecycle
objects can create multiple short-lived instances, making
initialize/activate/deactivate/free behavior unpredictable or incomplete.

## Examples

```dart
// BAD: Injectable + LifecycleMixin must not be factory-scoped.
class RoutingKitRoutingService extends RoutingService with LifecycleMixin {
  @override
  bool get singelton => false;
}
```

```dart
// GOOD: Injectable + LifecycleMixin resolves as singleton.
class RoutingKitRoutingService extends RoutingService with LifecycleMixin {
  @override
  bool get singelton => true;
}
```

```dart
// GOOD: Injectable without LifecycleMixin may remain non-singleton.
abstract class StatelessWorker extends Service {
  @override
  bool get singelton => false;
}
```

## Notes

This rule applies when `LifecycleMixin` is present in the class hierarchy
(mixed in directly or inherited), and the type is an `Injectable`.
