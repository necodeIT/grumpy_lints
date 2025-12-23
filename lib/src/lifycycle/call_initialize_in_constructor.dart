import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:grumpy_lints/src/utils/block.dart';
import 'package:grumpy_lints/src/utils/const.dart';
import 'package:grumpy_lints/src/utils/indentation.dart';
import 'package:grumpy_lints/src/utils/rule.dart';
import 'package:grumpy_lints/src/utils/superclass.dart';

class CallInitializeInConstructor extends DocumentedDartLintRule {
  const CallInitializeInConstructor() : super(code: _code);

  static const _code = LintCode(
    name: 'call_initialize_in_constructor',
    problemMessage:
        'A constructor of class with $kLifecycleMixin must call `$kInitializeMethod`.',
    correctionMessage:
        'Try adding `$kInitializeMethod();` at the end of the constructor body.',
    errorSeverity: DiagnosticSeverity.ERROR,
    url:
        'https://github.com/necodeIT/grumpy_lints#call_initialize_in_constructor',
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
      if (body is BlockFunctionBody) {
        if (body.block.callsMethodAnywhere(kInitializeMethod)) return;
      }

      reporter.atConstructorDeclaration(declaration, _code);
    });
  }

  @override
  List<Fix> getFixes() => [_Fix()];

  @override
  String get description =>
      '''
Enforces that every non-abstract class using `LifecycleMixin` calls `$kInitializeMethod()` in its constructor body.

Concrete types with `LifecycleMixin` are expected to trigger their lifecycle hooks (such as `onInitialize`) when an instance is created. If `$kInitializeMethod()` is never called, those hooks will silently never run, leading to partially-initialized objects and hard-to-track bugs.

This rule complements `avoid_abstract_initialize_calls`:
- abstract base classes **must not** call `initialize()` in their constructors
- concrete subclasses **must** call `initialize()` in theirs.
''';

  @override
  Map<String, String> get examples => {
    '''
// ✅ Correct: concrete class with LifecycleMixin calls initialize().
class MyService with LifecycleMixin {
  MyService() {
    // Custom setup...
    initialize();
  }
}
''': '''
// ❌ Incorrect: initialize() is never called in the constructor.
class MyService with LifecycleMixin {
  MyService() {
    // Custom setup...
  }
}
''',
    '''
// ✅ Correct: all non-factory constructors call initialize().
class MultiCtorService with LifecycleMixin {
  MultiCtorService() {
    initialize();
  }

  MultiCtorService.withConfig(Config config) {
    // Use config...
    initialize();
  }
}
''': '''
// ❌ Incorrect: one of the constructors forgets to call initialize().
class MultiCtorService with LifecycleMixin {
  MultiCtorService() {
    initialize();
  }

  MultiCtorService.withConfig(Config config) {
    // Use config...
    // Missing initialize();
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
      if (body.block.callsMethodAnywhere(kInitializeMethod)) return;

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
        message: 'Add initialize() to constructor body',
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleInsertion(
          insertionOffset,
          '$leadingNewline$indentDelta$kInitializeMethod();\n',
        );
      });
    });
  }
}
