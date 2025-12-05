import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

extension InterfaceElementExtensions on InterfaceElement {
  bool hasMethod(bool Function(MethodElement) test) {
    return methods.any(test);
  }

  MethodElement? findMethod(bool Function(MethodElement) test) {
    for (final method in methods) {
      if (test(method)) {
        return method;
      }
    }
    return null;
  }

  List<MethodElement> findMethods(bool Function(MethodElement) test) {
    return methods.where(test).toList();
  }

  List<MethodElement> findMethodsByAnnotation(
    String annotationType, {
    bool Function(DartObject)? additionalTest,
  }) {
    final typeChecker = TypeChecker.fromName(annotationType);
    return findMethods((method) {
      final annotations = typeChecker.firstAnnotationOf(method);

      return annotations != null &&
          (additionalTest == null || additionalTest(annotations));
    });
  }
}
