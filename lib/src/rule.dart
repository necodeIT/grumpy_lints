import 'package:analysis_server_plugin/registry.dart';
// ignore: implementation_imports
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/error/error.dart';
import 'package:grumpy_lints/src/context.dart';

abstract class GrumpyRule extends AnalysisRule {
  GrumpyRule({required super.name, required super.description});

  List<Example> get examples => [];

  Map<DiagnosticCode, ProducerGenerator> get fixes => {};

  void registerFixes(PluginRegistry registry) {
    for (var entry in fixes.entries) {
      registry.registerFixForRule(entry.key, entry.value);
    }
  }
}

class Example {
  final bool isGood;
  final String code;

  Example(this.isGood, this.code);

  @override
  String toString() {
    return '**${isGood ? '✅ DO' : '❌ DON\'T'}**\n```dart\n$code\n```';
  }
}

extension ExampleX on String {
  Example good() => Example(true, this);
  Example bad() => Example(false, this);
}

extension GrumpyX on RuleContext {
  GrumpyContext get grumpy => GrumpyContextBuilder().build(this);
}
