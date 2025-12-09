import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:modular_foundation_lints/src/architecture/fixes.dart';
import 'package:modular_foundation_lints/src/utils/const.dart';
import 'package:modular_foundation_lints/src/utils/rule.dart';

class RequireSuffix extends DocumentedDartLintRule {
  final String layer;
  final String suffix;
  @override
  final Map<String, String> examples;
  @override
  final String description;

  RequireSuffix({
    required this.layer,
    required this.suffix,
    Map<String, String>? examples,
    String? description,
  }) : examples =
           examples ??
           {
             '''
abstract class MyCustom$suffix extends $suffix {
  // Service implementation
}
''': '''
abstract class MyCustom {
  // Service implementation
}
''',
           },
       description =
           description ??
           '''A $layer class must have a name that ends with "$suffix" to ensure proper identification within the modular framework.''',
       super(
         code: LintCode(
           name: '${layer}_must_have_${suffix.toLowerCase()}_suffix',
           problemMessage:
               'A $layer declaration must have a name that ends with "$suffix" to ensure proper identification within the modular framework.',
           correctionMessage:
               'Try renaming the $layer class to have a "$suffix" suffix.',
           errorSeverity: DiagnosticSeverity.WARNING,
           url:
               'https://github.com/necodeIT/modular_foundation_lints#${layer}_must_have_${suffix.toLowerCase()}_suffix',
         ),
       );

  @override
  List<String> get filesToAnalyze => const ['**/datasources/**.dart'];

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((declaration) {
      final hasSuffix = declaration.name.lexeme.endsWith(kDatasourceClass);
      if (hasSuffix) return;

      reporter.atNode(declaration, code);
    });
  }

  @override
  List<Fix> getFixes() => [SuffixFix(suffix)];
}
