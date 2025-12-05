import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:modular_foundation_lints/src/utils/block.dart';
import 'package:modular_foundation_lints/src/utils/const.dart';
import 'package:modular_foundation_lints/src/utils/indentation.dart';
import 'package:modular_foundation_lints/src/utils/rule.dart';
import 'package:modular_foundation_lints/src/utils/superclass.dart';

class CallInitializeInConstructor extends DocumentedDartLintRule {
  const CallInitializeInConstructor() : super(code: _code);

  static const _code = LintCode(
    name: 'call_initialize_in_constructor',
    problemMessage:
        'A constructor of class with LifecycleMixin must call `$kInitializeMethod`.',
    correctionMessage:
        'Try adding `$kInitializeMethod();` at the end of the constructor body.',
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
  List<Fix> getFixes() => [_AddMissingInitializeCallFix()];

  @override
  String get description => '''
''';
}

class _AddMissingInitializeCallFix extends DartFix {
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
