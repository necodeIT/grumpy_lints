import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:modular_foundation_lints/src/utils/indentation.dart';
import 'package:modular_foundation_lints/src/utils/rule.dart';

class Installer {
  final String mixinName;
  final String methodName;
  final bool concreteOnly;

  Installer({
    required this.mixinName,
    required this.methodName,
    required this.concreteOnly,
  });
}

class ConstructorMustInstallHooks extends DocumentedDartLintRule {
  const ConstructorMustInstallHooks() : super(code: mustCallInstallHooks);

  static const mustCallInstallHooks = LintCode(
    name: 'constructor_must_call_install_hooks',
    problemMessage:
        'A constructor of a class with required hook mixins must call their installer methods.',
    correctionMessage:
        'Add the corresponding install*Hooks() call(s) to the constructor body.',
    errorSeverity: DiagnosticSeverity.ERROR,
    url:
        'https://github.com/necodeIT/modular_foundation_lints#constructor_must_call_install_hooks',
  );

  static LintCode mustCallInstallers(String mixin, String installer) {
    return LintCode(
      name: 'constructor_must_call_install_hooks',
      problemMessage:
          'A constructor of a class with $mixin must call $installer, as required by the mixin.',
      correctionMessage: 'Try adding `$installer();` to the constructor body.',
      errorSeverity: DiagnosticSeverity.ERROR,
      url:
          'https://github.com/necodeIT/modular_foundation_lints#constructor_must_call_install_hooks',
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

        if (_callsMethod(body.block, methodName)) continue;

        reporter.atConstructorDeclaration(
          declaration,
          mustCallInstallers(mixin, methodName),
        );
      }
    });
  }

  @override
  List<Fix> getFixes() => [_Fix()];
  @override
  String get description => '''
Ensures that any concrete class using mixins which expose installer-style hook methods (for example, `installLoggingHooks`, `installLifecycleHooks`) actually calls those methods from its constructor.

This rule scans mixins for methods named like `install*Hooks` (@mustCallInConstructor in the future). If a class mixes in such a mixin (directly or via a superclass), each `install*Hooks` method is treated as **required** at construction time. Missing installer calls usually mean hooks/listeners/telemetry are never wired up, even though the type advertises that behaviour via its mixins.

The fix inserts the missing `install*Hooks()` calls at the beginning of the constructor body.
''';

  @override
  Map<String, String> get examples => {
    '''
// ✅ Correct: constructor calls the installer from the mixin.
mixin LoggingHooks {
  @mustCallInConstructor
  void installLoggingHooks() {
    // set up loggers, sinks, etc.
  }
}

class UserService with LoggingHooks {
  UserService() {
    installLoggingHooks();
    // other setup...
  }
}
''': '''
// ❌ Incorrect: mixin is used, but its installer is never called.
mixin LoggingHooks { 
  @mustCallInConstructor
  void installLoggingHooks() {
    // set up loggers, sinks, etc.
  }
}

class UserService with LoggingHooks {
  UserService() {
    // other setup...
    // Missing: installLoggingHooks();
  }
}
''',
    '''
// ✅ Correct: subclass still calls installers from a mixin on the base class.
mixin MetricsHooks {
  @mustCallInConstructor
  void installMetricsHooks() {}
}

abstract class BaseService with MetricsHooks {
  BaseService();
}

class OrdersService extends BaseService {
  OrdersService() : super() {
    installMetricsHooks();
  }
}
''': '''
// ❌ Incorrect: subclass relies on mixin from superclass but forgets installer.
mixin MetricsHooks {
  @mustCallInConstructor
  void installMetricsHooks() {}
}

abstract class BaseService with MetricsHooks {
  BaseService();
}

class OrdersService extends BaseService {
  OrdersService() : super() {
    // Missing: installMetricsHooks();
  }
}
''',
  };
}

class _Fix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic analysisError,
    List<Diagnostic> others,
  ) {
    context.registry.addConstructorDeclaration((declaration) {
      if (!analysisError.sourceRange.intersects(declaration.sourceRange)) {
        return;
      }

      final body = declaration.body;
      if (body is! BlockFunctionBody) return;

      final enclosing = declaration.thisOrAncestorOfType<ClassDeclaration>();
      if (enclosing == null || enclosing.abstractKeyword != null) return;

      final installers = _getInstallers(enclosing);
      if (installers.isEmpty) return;

      final missingInstallerCalls = installers.values
          .where((installer) => !_callsMethod(body.block, installer))
          .toList();

      if (missingInstallerCalls.isEmpty) return;

      final insertionOffset = body.block.statements.isNotEmpty
          ? body.block.statements.first.offset
          : body.block.rightBracket.offset;

      final indent = indentForBlockStatement(body.block, resolver);
      final existingIndent = indentForOffset(resolver, insertionOffset);
      final indentDelta = missingIndent(indent, existingIndent);
      final leadingNewline = leadingNewlineForInsertion(
        body.block,
        resolver,
        insertionOffset,
      );

      final changeBuilder = reporter.createChangeBuilder(
        message: missingInstallerCalls.length == 1
            ? 'Call ${missingInstallerCalls.single}()'
            : 'Call required install hooks',
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        final buffer = StringBuffer(leadingNewline);
        for (final installer in missingInstallerCalls) {
          buffer
            ..write(indentDelta)
            ..write(installer)
            ..writeln('();');
        }

        if (body.block.statements.isNotEmpty) {
          buffer.write(indent);
        }

        builder.addSimpleInsertion(insertionOffset, buffer.toString());
      });
    });
  }
}

bool _callsMethod(Block block, String methodName) {
  return block.statements.any((statement) {
    return statement is ExpressionStatement &&
        statement.expression is MethodInvocation &&
        (statement.expression as MethodInvocation).methodName.name ==
            methodName;
  });
}

Map<String, String> _getInstallers(ClassDeclaration element) {
  final installers = <String, String>{};

  for (final mixin in element.withClause?.mixinTypes ?? []) {
    final mixinElement = mixin.type?.element;
    if (mixinElement is MixinElement) {
      for (final method in mixinElement.methods) {
        final name = method.name ?? '';
        // TODO: replace with @mustCallInConstructor annotation check
        if (name.startsWith('install') && name.endsWith('Hooks')) {
          installers[mixinElement.name!] = name;
        }
      }
    }
  }

  return installers..addAll(
    _getSuperClassInstallers(element.extendsClause?.superclass.element),
  );
}

Map<String, String> _getSuperClassInstallers(Element? element) {
  final installers = <String, String>{};

  if (element == null) return installers;

  if (element is ClassElement) {
    for (final mixin in element.mixins) {
      final mixinElement = mixin.element;
      if (mixinElement is MixinElement) {
        for (final method in mixinElement.methods) {
          final name = method.name ?? '';

          // TODO: replace with @mustCallInConstructor annotation check
          if (name.startsWith('install') && name.endsWith('Hooks')) {
            installers[mixinElement.name!] = name;
          }
        }
      }
    }

    final superInstallers = _getSuperClassInstallers(
      element.supertype?.element,
    );
    installers.addAll(superInstallers);
  }

  return installers;
}
