import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ConstructorMustCallInitialize extends DartLintRule {
  ConstructorMustCallInitialize() : super(code: doesNotCall);

  static const doesNotCall = LintCode(
    name: 'constructor_must_call_initialize',
    problemMessage:
        'A constructor of class with LifecycleMixin must call `initialize` at the **end** of its body.',
    correctionMessage:
        'Try adding `initialize();` to the **end** of the constructor body.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  static const callsInAbstract = LintCode(
    name: 'avoid_initialize_call_in_abstract_class_constructors',
    problemMessage:
        'An abstract class constructor must not call `initialize` since it cannot be instantiated.',
    correctionMessage:
        'Try removing `initialize();` from the constructor body and call it in the constructors of concrete subclasses instead.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  static const isNotAtTheEnd = LintCode(
    name: 'call_initialize_at_end_of_constructor',
    problemMessage:
        '`initialize` should be called at the end of the constructor body.',
    correctionMessage:
        'Try moving `initialize();` to the end of the constructor body.',
    errorSeverity: DiagnosticSeverity.INFO,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addConstructorDeclaration((declaration) {
      if (declaration.externalKeyword != null) return;
      if (declaration.factoryKeyword != null) return;
      if (declaration.redirectedConstructor != null) return;

      final body = declaration.body;
      if (body is! BlockFunctionBody) return;

      final enclosing = declaration.thisOrAncestorOfType<ClassDeclaration>()!;

      if (!_hasLifecycleMixin(enclosing)) {
        print(
          'Skipping ${enclosing.name} since it does not have LifecycleMixin',
        );
        return;
      }

      final isAbstract = enclosing.abstractKeyword != null;

      final anyCallsInitialize = body.block.statements.any((statement) {
        return statement is ExpressionStatement &&
            statement.expression is MethodInvocation &&
            (statement.expression as MethodInvocation).methodName.name ==
                'initialize';
      });

      final lastCallsInitialize =
          body.block.statements.isNotEmpty &&
          body.block.statements.last is ExpressionStatement &&
          (body.block.statements.last as ExpressionStatement).expression
              is MethodInvocation &&
          ((body.block.statements.last as ExpressionStatement).expression
                      as MethodInvocation)
                  .methodName
                  .name ==
              'initialize';

      print(
        'anyCallsInitialize: $anyCallsInitialize | lastCallsInitialize: $lastCallsInitialize | isAbstract: $isAbstract',
      );

      if (isAbstract && anyCallsInitialize) {
        reporter.atConstructorDeclaration(declaration, callsInAbstract);
        return;
      }

      if (!isAbstract && !anyCallsInitialize) {
        reporter.atConstructorDeclaration(declaration, doesNotCall);
        return;
      }

      if (anyCallsInitialize && !lastCallsInitialize) {
        reporter.atConstructorDeclaration(declaration, isNotAtTheEnd);
      }
    });
  }

  bool _hasLifecycleMixin(ClassDeclaration element) {
    for (final mixin in element.withClause?.mixinTypes ?? []) {
      final mixinElement = mixin.type?.element;
      if (mixinElement?.name == 'LifecycleMixin') {
        return true;
      }
    }

    final superClass = element.extendsClause?.superclass;
    if (superClass == null) return false;
    return _checkSuperClass(superClass.element);
    // final superclass = element.parent?.thisOrAncestorOfType<ClassDeclaration>();
    // return _hasLifecycleMixin(superClass);

  }

  bool _checkSuperClass(Element? element) {
    if (element == null) return false;

    if (element.name == 'Object') return false;

    if (element is ClassElement) {
      for (final mixin in element.mixins) {
        if (mixin.element.name == 'LifecycleMixin') {
          return true;
        }
      }

      return _checkSuperClass(element.supertype?.element);
    }

    return false;
  }
}

class ConstructorMustInstallHooks extends DartLintRule {
  ConstructorMustInstallHooks() : super(code: mustCallInstallHooks);

  static const mustCallInstallHooks = LintCode(
    name: 'constructor_must_call_install_hooks',
    problemMessage:
        'A constructor of class with LifecycleMixin must call installHooks() at the **beginning** of its body.',
    correctionMessage:
        'Try adding `installHooks();` to the **beginning** of the constructor body.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  static LintCode mustCallInstallers(String mixin, String installer) {
    return LintCode(
      name: 'constructor_must_call_install_hooks',
      problemMessage:
          'A constructor of a class with $mixin must call $installer, as required by the mixin.',
      correctionMessage: 'Try adding `$installer();` to the constructor body.',
      errorSeverity: DiagnosticSeverity.ERROR,
    );
  }

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addConstructorDeclaration((declaration) {
      if (declaration.externalKeyword != null) return;
      if (declaration.factoryKeyword != null) return;
      if (declaration.redirectedConstructor != null) return;

      final body = declaration.body;
      if (body is! BlockFunctionBody) return;

      final enclosing = declaration.thisOrAncestorOfType<ClassDeclaration>()!;
      if (enclosing.abstractKeyword != null) return;

      final installers = _getInstallers(enclosing);
      if (installers.isEmpty) return;

      for (final installer in installers.entries) {
        final mixin = installer.key;
        final methodName = installer.value;

        final callsInstaller = body.block.statements.any((statement) {
          return statement is ExpressionStatement &&
              statement.expression is MethodInvocation &&
              (statement.expression as MethodInvocation).methodName.name ==
                  methodName;
        });

        if (!callsInstaller) {
          reporter.atConstructorDeclaration(
            declaration,
            mustCallInstallers(mixin, methodName),
          );
        }
      }
    });
  }

  Map<String, String> _getInstallers(ClassDeclaration element) {
    final installers = <String, String>{};

    for (final mixin in element.withClause?.mixinTypes ?? []) {
      final mixinElement = mixin.type?.element;
      if (mixinElement is MixinElement) {
        for (final method in mixinElement.methods) {
          final name = method.name ?? '';

          if (name.startsWith('install') && name.endsWith('Hooks')) {
            installers[mixinElement.name!] = name;
          }
        }
      }
    }

    return installers;
  }

  Map<String>
}
