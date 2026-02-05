# Prefer Domain DI Factory

## Intent

Encourage consumers to obtain domain services and datasources via the
standardized DI factory constructor instead of calling static DI accessors
like `Service.get<T>()` or `Datasource.get<T>()` directly.

## Rule

In non-domain layers (presentation/infra), avoid direct calls to
`Service.get<T>()`, `Datasource.get<T>()`, or similar static DI accessors for
domain contracts. Prefer using the domain contract's DI factory constructor
(e.g., `RoutingService()` or `UserDatasource()`).

## Severity

Info.

## Rationale

Calling the domain factory keeps dependency usage consistent, reduces DI
knowledge in non-domain code, and makes contracts easier to swap or mock.
It also centralizes DI access patterns in the domain layer.

## Examples

```dart
// BAD: direct DI access
final routing = Service.get<RoutingService>();
final users = Datasource.get<UserDatasource>();
```

```dart
// GOOD: use domain factory constructors
final routing = RoutingService();
final users = UserDatasource();
```

## Notes

This rule does not apply inside the domain layer itself (where factories are
implemented). Only flag usage in other layers.
