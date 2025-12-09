import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:modular_foundation_lints/src/architecture/fixes.dart';
import 'package:modular_foundation_lints/src/utils/rule.dart';

class RequireSuffix extends DocumentedDartLintRule {
  final String layer;
  final String suffix;
  @override
  final Map<String, String> examples;
  @override
  final String description;
  @override
  final bool enabledByDefault;

  RequireSuffix({
    required this.layer,
    required this.suffix,
    Map<String, String>? examples,
    String? description,
    this.enabledByDefault = true,
  }) : examples =
           examples ??
           {
             '''
// ✅ Correct: class name follows the "$suffix" convention.
abstract class UserAccount$suffix {
  // $layer implementation
}
''':
                 '''
// ❌ Incorrect: missing the required "$suffix" suffix.
abstract class UserAccount {
  // $layer implementation
}
''',
             '''
// ✅ Correct: concrete class also uses the "$suffix" suffix.
class PaymentProcessing$suffix {
  // ...
}
''':
                 '''
// ❌ Incorrect: same concept without the "$suffix" suffix.
class PaymentProcessing {
  // ...
}
''',
           },
       description =
           description ??
           'Enforces a naming convention for the `$layer` layer: all classes '
               'must end with the `$suffix` suffix.\n\n'
               'This keeps responsibilities easy to spot (by name alone), '
               'improves search/filters in large codebases, and makes the '
               'modular architecture predictable.',
       super(
         code: LintCode(
           name: '${layer}_must_have_${suffix.toLowerCase()}_suffix',
           problemMessage:
               'Classes in the "$layer" layer must have names that end with '
               '"$suffix" to follow the naming convention.',
           correctionMessage:
               'Rename this class so its name ends with "$suffix".',
           errorSeverity: DiagnosticSeverity.WARNING,
           url:
               'https://github.com/necodeIT/modular_foundation_lints#${layer}_must_have_${suffix.toLowerCase()}_suffix',
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
      final hasSuffix = declaration.name.lexeme.endsWith(suffix);
      if (hasSuffix) return;

      reporter.atNode(declaration, code);
    });
  }

  @override
  List<Fix> getFixes() => [SuffixFix(suffix)];
}
