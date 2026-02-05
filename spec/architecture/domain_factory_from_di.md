# Domain Services/Datasources Must Expose DI Factory

## Intent

Make domain contracts easy to obtain via dependency injection (DI) by
standardizing a factory constructor that returns the registered
implementation.

## Rule

All classes defined in the domain layer under `domain/services` and
`domain/datasources` must declare a factory constructor that retrieves the
implementation from DI, except for the base class itself (e.g., `Service`,
`Datasource`).

The factory must return the interface type and use the DI accessor (e.g.,
`Service.get<T>()`).

## Severity

Info.

## Rationale

A consistent DI factory on every domain contract makes usage predictable and
avoids direct instantiation. It also keeps the domain boundary explicit while
allowing infra to supply implementations.

## Examples

```dart
// BAD: missing factory constructor
// File: lib/src/module/domain/services/routing_service.dart
abstract class RoutingService<T, Config> extends Service {}
```

```dart
// GOOD: factory constructor resolves from DI
// File: lib/src/module/domain/services/routing_service.dart
abstract class RoutingService<T, Config> extends Service {
  /// Returns the DI-registered implementation of [RoutingService].
  factory RoutingService() {
    return Service.get<RoutingService<T, Config>>();
  }
}
```

```dart
// GOOD: base class is exempt
// File: lib/src/core/domain/services/service.dart
abstract class Service {
  static T get<T>() => /* ... */ throw UnimplementedError();
}
```

## Notes

The lint fix should generate the factory constructor with a doc comment in
domain services and datasources when it is missing.
