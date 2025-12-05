import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

extension RecursiveChecks on Element? {
  bool anySuperclass(bool Function(ClassElement) test) {
    if (this == null) return false;

    if (this!.name == 'Object') return false;

    if (this is ClassElement) {
      final clazz = this as ClassElement;

      if (test(clazz)) {
        return true;
      }

      return clazz.supertype?.element.anySuperclass(test) ?? false;
    }

    return false;
  }

  bool hasSuperclass(String superclassName) =>
      anySuperclass((clazz) => clazz.name == superclassName);

  bool hasMixin(String mixinName) => anySuperclass((clazz) {
    for (final mixin in clazz.mixins) {
      final mixinElement = mixin.element;
      if (mixinElement.name == mixinName) {
        return true;
      }
    }
    return false;
  });
}

extension ClassDeclarationExtensions on ClassDeclaration {
  bool anySuperclass(bool Function(ClassElement) test) {
    final superClass = extendsClause?.superclass;
    if (superClass == null) return false;
    final element = superClass.element;
    if (element is ClassElement) {
      if (test(element)) {
        return true;
      }
      return element.anySuperclass(test);
    }
    return false;
  }

  bool hasSuperclass(String superclassName) {
    final superClass = extendsClause?.superclass;
    if (superClass == null) return false;
    if (superClass.name.lexeme == superclassName) {
      return true;
    }
    return superClass.element.hasSuperclass(superclassName);
  }

  bool hasMixin(String mixinName) {
    for (final mixin in withClause?.mixinTypes ?? []) {
      final mixinElement = mixin.type?.element;
      if (mixinElement?.name == mixinName) {
        return true;
      }
    }

    final superClass = extendsClause?.superclass;
    if (superClass == null) return false;
    return superClass.element.hasMixin(mixinName);
  }
}
