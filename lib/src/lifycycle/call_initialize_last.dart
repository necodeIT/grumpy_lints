import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:modular_foundation_lints/src/utils/block.dart';
import 'package:modular_foundation_lints/src/utils/const.dart';
import 'package:modular_foundation_lints/src/utils/indentation.dart';
import 'package:modular_foundation_lints/src/utils/rule.dart';
import 'package:modular_foundation_lints/src/utils/superclass.dart';

class CallInitializeLast extends DocumentedDartLintRule {
  const CallInitializeLast() : super(code: _code);

  static const _code = LintCode(
    name: 'call_initialize_last',
    problemMessage:
        '`$kInitializeMethod` should be called at the end of the constructor body.',
    correctionMessage:
        'Try moving `$kInitializeMethod();` to the end of the constructor body.',
    errorSeverity: DiagnosticSeverity.WARNING,
    url:
        'https://github.com/necodeIT/modular_foundation_lints#call_initialize_last',
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

      if (clazz.abstractKeyword != null) return;

      final hasLifecycleMixin = clazz.hasMixin(kLifecycleMixin);
      if (!hasLifecycleMixin) return;

      final body = declaration.body;
      if (body is! BlockFunctionBody) return;
      if (!body.block.callsMethodAnywhere(kInitializeMethod)) return;
      if (body.block.callsMethodAtEnd(kInitializeMethod)) return;

      reporter.atConstructorDeclaration(declaration, _code);
    });
  }

  @override
  List<Fix> getFixes() => [_Fix()];

  @override
  String get description =>
      '''
Enforces that `$kInitializeMethod()` is the *last* statement in the constructor body of concrete classes using `LifecycleMixin`.

`$kInitializeMethod()` typically triggers lifecycle callbacks (such as `onInitialize`). If you keep doing work after that call — mutating fields, registering listeners, emitting events — that logic runs **after** the lifecycle phase, and consumers may see a half-initialized object.

By always calling `$kInitializeMethod()` last, you ensure that:

- all constructor setup runs before lifecycle hooks observe the instance
- there is a clear, predictable "end of initialization" point
- side-effects after construction are not accidentally executed during initialization.
''';

  @override
  Map<String, String> get examples => {
    '''
// ✅ Correct: initialize() is called last.
class MyService with LifecycleMixin {
  MyService(Dependency dep) {
    _dep = dep;
    _configure();
    initialize();
  }

  late final Dependency _dep;

  void _configure() {
    // setup...
  }
}
''': '''
// ❌ Incorrect: work happens after initialize().
class MyService with LifecycleMixin {
  MyService(Dependency dep) {
    _dep = dep;
    initialize(); // Lifecycle hooks run here...

    _configure(); // ...but more setup happens afterwards.
  }

  late final Dependency _dep;

  void _configure() {
    // setup...
  }
}
''',
    '''
// ✅ Correct: guard logic + branching before initialize(), nothing after.
class ConditionalService with LifecycleMixin {
  ConditionalService(bool enabled) {
    if (!enabled) {
      _disabled = true;
      initialize();
      return;
    }

    _disabled = false;
    _prepareHeavyResources();
    initialize();
  }

  bool _disabled = false;

  void _prepareHeavyResources() {}
}
''': '''
// ❌ Incorrect: logic after initialize() in some branches.
class ConditionalService with LifecycleMixin {
  ConditionalService(bool enabled) {
    if (!enabled) {
      _disabled = true;
      initialize();
      return;
    }

    _disabled = false;
    initialize(); // Called too early.
    _prepareHeavyResources(); // Runs after lifecycle hooks.
  }

  bool _disabled = false;

  void _prepareHeavyResources() {}
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

      final initializeCalls = body.block.statements
          .whereType<ExpressionStatement>()
          .where(_isInitializeInvocation)
          .toList();

      if (initializeCalls.isEmpty) return;

      final statementToMove = initializeCalls.last;
      if (body.block.statements.isNotEmpty &&
          identical(body.block.statements.last, statementToMove)) {
        return;
      }

      final insertionOffset = body.block.rightBracket.offset;
      final indent = indentForBlockStatement(body.block, resolver);
      final existingIndent = indentForOffset(resolver, insertionOffset);
      final indentDelta = missingIndent(indent, existingIndent);
      final leadingNewline = leadingNewlineForInsertion(
        body.block,
        resolver,
        insertionOffset,
      );

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Move initialize() to the end of the constructor body',
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addDeletion(
          SourceRange(statementToMove.offset, statementToMove.length),
        );
        builder.addSimpleInsertion(
          insertionOffset,
          '$leadingNewline$indentDelta${statementToMove.toSource()}\n',
        );
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
