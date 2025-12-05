import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:modular_foundation_lints/src/utils/block.dart';
import 'package:modular_foundation_lints/src/utils/const.dart';
import 'package:modular_foundation_lints/src/utils/rule.dart';
import 'package:modular_foundation_lints/src/utils/superclass.dart';

class AvoidAbstractInitializeCalls extends DocumentedDartLintRule {
  const AvoidAbstractInitializeCalls() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_abstract_initialize_calls',
    problemMessage:
        'An abstract class constructor must not call `initialize` since it cannot be instantiated.',
    correctionMessage:
        'Try removing `initialize();` from the constructor body and call it in the constructors of concrete subclasses instead.',
    errorSeverity: DiagnosticSeverity.ERROR,
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

      final clazz = declaration.thisOrAncestorOfType<ClassDeclaration>()!;

      if (clazz.abstractKeyword == null) return;

      final hasLifecycleMixin = clazz.hasMixin(kLifecycleMixin);
      if (!hasLifecycleMixin) return;

      final body = declaration.body;
      if (body is! BlockFunctionBody) return;
      if (!body.block.callsMethodAnywhere(kInitializeMethod)) return;

      reporter.atConstructorDeclaration(declaration, _code);
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveInitializeFromAbstractConstructor()];

  @override
  String get description => '''
Abstract classes with a LifecycleMixin should not call `initialize()` in their constructors, as abstract classes cannot be instantiated. Calling `initialize()` in an abstract class will fire the onInitialize lifecycle event prematurely, potentially leading to unexpected behavior.

Instead, `initialize()` should be called in the constructors of concrete subclasses that extend the abstract class. This ensures that the lifecycle events are triggered appropriately when instances of the concrete classes are created.
''';

  @override
  Map<String, String> get examples => {
    '''
class MyConcreteClass extends MyBaseClass {
  MyConcreteClass() : super() {
    // Correct: Calling initialize in a concrete class
    initialize();
  }
}
''': '''
abstract class MyBaseClass with LifecycleMixin {
  MyBaseClass() {
    // Incorrect: Calling initialize in an abstract class
    initialize();
  }
}
''',
  };
}

class _RemoveInitializeFromAbstractConstructor extends DartFix {
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

      final initializeCalls = body.block.statements
          .whereType<ExpressionStatement>()
          .where(_isInitializeInvocation)
          .toList();

      if (initializeCalls.isEmpty) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Remove initialize() from abstract constructor',
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        for (final statement in initializeCalls.reversed) {
          builder.addDeletion(SourceRange(statement.offset, statement.length));
        }
      });
    });
  }

  bool _isInitializeInvocation(Statement statement) {
    return statement is ExpressionStatement &&
        statement.expression is MethodInvocation &&
        (statement.expression as MethodInvocation).methodName.name ==
            kInitializeMethod;
  }
}
