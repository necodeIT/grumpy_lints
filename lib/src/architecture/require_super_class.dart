import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:grumpy_lints/src/architecture/fixes.dart';
import 'package:grumpy_lints/src/utils/rule.dart';
import 'package:grumpy_lints/src/utils/superclass.dart';

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
           'Require all classes in the `$layer` layer to extend `$superClassName`.\n\n'
               'This ensures a consistent API for the modular framework '
               '(e.g. lifecycle hooks, logging, error handling) and prevents '
               'classes from silently opting out of the shared behaviour.',
       examples =
           examples ??
           {
             // ✅ good  -> ❌ bad
             '''
// ✅ Correct: extends the required base class.
abstract class My$superClassName extends $superClassName {
  // ${superClassName.toLowerCase()} implementation
}
''':
                 '''
// ❌ Incorrect: does not extend the required base class.
abstract class My$superClassName {
  // ${superClassName.toLowerCase()} implementation
}
''',
             '''
// ✅ Correct: concrete class in the "$layer" layer extends the base type.
class UserProfile$superClassName extends $superClassName {
  // ...
}
''':
                 '''
// ❌ Incorrect: concrete class in the "$layer" layer without the base type.
class UserProfile$superClassName {
  // ...
}
''',
           },
       super(
         code: LintCode(
           name: '${layer}_must_extend_${superClassName.toLowerCase()}',
           problemMessage:
               'Classes in the "$layer" layer must extend $superClassName '
               'so the modular framework can treat them uniformly.',
           correctionMessage: 'Extend $superClassName from this class.',
           errorSeverity: DiagnosticSeverity.ERROR,
           url:
               'https://github.com/necodeIT/grumpy_lints#${layer}_must_extend_${superClassName.toLowerCase()}',
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
