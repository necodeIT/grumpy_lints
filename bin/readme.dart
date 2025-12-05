import 'dart:io';

import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:modular_foundation_lints/modular_foundation_lints.dart';

void main(List<String> args) {
  final f = File('README.template');
  var template = f.readAsStringSync();

  final regex = RegExp(r"{{rules\((\d*)\)}}");

  final match = regex.firstMatch(template)!;

  final count = int.parse(match.group(1) ?? '0');

  final headerLevel = '#' * count;
  final subHeaderLevel = '#' * (count + 1);

  final rulesBuffer = StringBuffer();

  rulesBuffer.writeln(
    '| Rule | Overview | Severity | Enabled by Default | Fix Available |',
  );

  rulesBuffer.writeln(
    '| ---- | -------- | -------- | ------------------ | ------------- |',
  );

  for (final rule in rules) {
    final ruleName = rule.code.name;
    final overview = rule.code.problemMessage;
    final severity = rule.code.errorSeverity.name;
    final enabledByDefault = rule.enabledByDefault ? 'Yes' : 'No';
    final fixAvailable = rule.getFixes().isNotEmpty ? '✅' : '❌';

    rulesBuffer.writeln(
      '| [$ruleName](#${ruleName.toLowerCase()}) | $overview | $severity | $enabledByDefault | $fixAvailable |',
    );
  }

  for (final rule in rules) {
    final ruleName = rule.code.name;
    final details = rule.description.isEmpty
        ? 'No additional details provided.'
        : rule.description;
    final examples = rule.examples.isNotEmpty
        ? rule.examples.entries
              .map(
                (e) =>
                    '**✅ DO**\n```dart\n${e.key}\n```\n\n**❌ DON\'T**\n```dart\n${e.value}\n```',
              )
              .join('\n\n')
        : 'No examples provided.';

    rulesBuffer.writeln('\n\n');
    rulesBuffer.writeln('$headerLevel $ruleName\n');
    rulesBuffer.writeln(details);
    rulesBuffer.writeln('$subHeaderLevel Examples\n$examples\n');
  }

  template = template.replaceFirst(regex, rulesBuffer.toString());

  final outputFile = File('README.md');
  outputFile.writeAsStringSync(template);
}
