import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:modular_foundation_lints/src/architecture/fixes.dart';
import 'package:modular_foundation_lints/src/utils/rule.dart';
import 'package:modular_foundation_lints/src/utils/superclass.dart';

class RequireSuperClass extends DocumentedDartLintRule {
  final String layer;
  final String superClassName;

  @override
  final Map<String, String> examples;

  @override
  final String description;

  RequireSuperClass({
    required this.layer,
    required this.superClassName,
    String? description,
    Map<String, String>? examples,
  }) : description =
           description ??
           '''
A ${superClassName.toLowerCase()} class must extend the base `$superClassName` class provided by the modular framework. This ensures that the ${superClassName.toLowerCase()} integrates properly with the framework's lifecycle management, dependency injection, and other core functionalities.''',
       examples =
           examples ??
           {
             '''
abstract class My$superClassName extends $superClassName {
  // ${superClassName.toLowerCase()} implementation
}
''':
                 '''
abstract class My$superClassName {
  // ${superClassName.toLowerCase()} implementation
}
''',
           },
       super(
         code: LintCode(
           name: '${layer}_must_extend_${superClassName.toLowerCase()}',
           problemMessage:
               'A ${superClassName.toLowerCase()} declaration in $layer must extend the base $superClassName class to ensure proper functionality within the modular framework.',
           correctionMessage:
               'Try extending the $superClassName class in your service declaration.',
           errorSeverity: DiagnosticSeverity.ERROR,
           url:
               'https://github.com/necodeIT/modular_foundation_lints#${layer}_must_extend_${superClassName.toLowerCase()}',
         ),
       );

  @override
  List<String> get filesToAnalyze => ['**/$layer/**.dart'];

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((declaration) {
      final extendsSuperClass = declaration.anySuperclass(
        (element) => element.name == superClassName,
      );

      if (extendsSuperClass) return;

      reporter.atNode(declaration, code);
    });
  }

  @override
  List<Fix> getFixes() => [ExtendFix(superClassName)];
}
