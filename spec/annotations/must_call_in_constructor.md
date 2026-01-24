Classes that mixin or inherit from a class that has any methods annotated
with `@MustCallInConstructor` must ensure that those methods are called in
their constructors. If the `concreteOnly` parameter is set to true, this rule
applies only to non-abstract classes. If the class is a subtype of any type
listed in the `exceptions` parameter, it is exempt from this requirement.
