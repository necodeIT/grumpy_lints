import 'package:custom_lint_builder/custom_lint_builder.dart';

abstract class DocumentedDartLintRule extends DartLintRule {
  const DocumentedDartLintRule({required super.code});

  /// A more detailed description of the lint rule than [code.problemMessage].
  String get description => '';

  /// A map of examples where the key is a good example and the value is a bad example.
  Map<String, String> get examples => {};
}
