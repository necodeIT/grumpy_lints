# Leaf Preview Must Not Use Injectables Or Navigation

## Intent

Guarantee that `Leaf.preview` remains side-effect free and independent from
module readiness by prohibiting any use of DI-managed runtime dependencies and
navigation APIs, including transitive calls in its reachable call stack.

## Rule

For every override of `Leaf.preview(RouteContext)`, emit a warning if the method
body or any reachable call in its static call graph performs one of the
forbidden operations.

### Forbidden operations

1. Resolving or constructing any `Injectable` contract or implementation.
2. Accessing DI directly (for example, `GetIt.instance.get*`,
   `Service.get<T>()`, `Datasource.get<T>()`, `Repo.get<T>()`).
3. Calling any method on values whose static type is `Injectable` (or subtype).
4. Using navigation services or navigation actions (for example,
   `RoutingService().navigate(...)`) directly or transitively.

This applies both to direct code inside `preview` and indirect usage through
helper functions/methods in the call stack.

## Severity

Warning.

## Rationale

`Leaf.preview` executes before route dependency activation is guaranteed.
Using `Injectable` instances or navigation in preview can cause race
conditions, module-readiness violations, or hidden side effects.

A transitive (call-stack) rule is required because most violations appear in
helper methods rather than directly in `preview`.

## Detection Strategy

### Entry points

- Methods that override `Leaf.preview(RouteContext)`.

### Forbidden sinks

Treat any of the following as a sink:

1. Constructor invocation where the constructed type is assignable to
   `Injectable`.
2. Constructor invocation of `RoutingService` (or known navigation contracts).
3. Invocations of known DI accessors:
   - `Service.get<T>()`
   - `Datasource.get<T>()`
   - `Repo.get<T>()`
   - `GetIt.instance.get(...)`
   - `GetIt.instance.getAsync(...)`
   - other equivalent `GetIt` resolve APIs
4. Method invocations where receiver type is `Injectable` and method is not
   provably pure/local-value-only.
5. Calls to `navigate` on `RoutingService`-typed receivers.

### Call-stack traversal

- Build a static call graph from each `preview` body.
- Traverse reachable calls within the current package/library source set.
- If any reachable sink is found, report on the `preview` override.
- Include a short path in the diagnostic message when available:
  `preview -> helperA -> helperB -> Service.get<NetworkService>()`.

## Examples

```dart
// BAD: direct DI usage in preview
class HomeLeaf extends Leaf<Widget> {
  @override
  Widget preview(RouteContext ctx) {
    final api = NetworkService();
    return Loading(api.statusText);
  }

  @override
  Widget content(RouteContext ctx) => const SizedBox();
}
```

```dart
// BAD: transitive DI usage
class HomeLeaf extends Leaf<Widget> {
  @override
  Widget preview(RouteContext ctx) {
    return buildLoading();
  }

  Widget buildLoading() {
    return _titleFromConfig();
  }

  Widget _titleFromConfig() {
    final api = NetworkService();
    return Loading(api.statusText);
  }

  @override
  Widget content(RouteContext ctx) => const SizedBox();
}
```

```dart
// BAD: navigation in preview
class HomeLeaf extends Leaf<Widget> {
  @override
  Widget preview(RouteContext ctx) {
    RoutingService<AppView, AppConfig>().navigate('/login');
    return const Spinner();
  }

  @override
  Widget content(RouteContext ctx) => const SizedBox();
}
```

```dart
// GOOD: preview is pure and placeholder-only
class HomeLeaf extends Leaf<Widget> {
  @override
  Widget preview(RouteContext ctx) {
    return const Spinner();
  }

  @override
  Widget content(RouteContext ctx) async {
    final api = NetworkService();
    final data = await api.fetch();
    return DataView(data);
  }
}
```

## Notes

1. This rule is intentionally strict and may produce conservative warnings when
   static analysis cannot prove safety.
2. Calls that cannot be resolved statically should default to warning when they
   originate from `preview` and may reach forbidden sinks.
3. External package methods may be treated as opaque; in that case, only direct
   sinks at the call site are guaranteed to be detected.
4. No quick-fix is required initially; suggested remediation text should be:
   move dependency/navigation access to `content` or middleware.

## Implementation Guidance

1. Add this rule under architecture lints and enable by default.
2. Reuse type-check helpers used by existing DI-related lints.
3. Implement sink matching first (direct violations), then extend to transitive
   traversal in a second iteration if needed for performance tuning.
4. Add regression tests for:
   - direct DI in preview
   - transitive DI in preview
   - direct navigation in preview
   - transitive navigation in preview
   - legal usage in `content`
