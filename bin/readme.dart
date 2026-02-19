import 'dart:io';

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:grumpy_lints/main.dart';

void main(List<String> args) {
  final f = File('README.template');
  var template = f.readAsStringSync();

  final rulesRegex = RegExp(r"{{rules\((\d*)\)}}");

  final match = rulesRegex.firstMatch(template)!;

  final count = int.parse(match.group(1) ?? '0');

  final headerLevel = '#' * count;
  final subHeaderLevel = '#' * (count + 1);

  final rulesBuffer = StringBuffer();

  rulesBuffer.writeln('| Rule | Overview | Severity | Fix Available | Codes |');

  rulesBuffer.writeln('| --- | --- | --- | --- | --- |');

  final rules = [...GrumpyLints.warnings, ...GrumpyLints.errors];

  for (final rule in rules) {
    final ruleName = rule.name;
    final overview = rule.description.split('\n').first.split('. ').first;
    final severity = _maxSeverity(
      rule.diagnosticCodes.map((code) => code.severity),
    ).name;
    final fixAvailable = rule.fixes.isNotEmpty ? '✅' : '❌';

    rulesBuffer.writeln(
      '| [$ruleName](#${ruleName.toLowerCase()}) | $overview | $severity | $fixAvailable | ${rule.diagnosticCodes.length} |',
    );
  }

  for (final rule in rules) {
    final ruleName = rule.name;
    final details = rule.description.isEmpty
        ? 'No additional details provided.'
        : rule.description;
    final codes = rule.diagnosticCodes.isNotEmpty
        ? rule.diagnosticCodes
              .map(
                (code) => '- `${code.lowerCaseName}` (${code.severity.name})',
              )
              .join('\n')
        : 'No diagnostic codes.';
    final examples = rule.examples.isNotEmpty
        ? rule.examples
              .map(
                (e) =>
                    '**${e.isGood ? '✅ DO' : '❌ DON\'T'}**\n```dart\n${e.code}\n```',
              )
              .join('\n\n')
        : 'No examples provided.';

    rulesBuffer.writeln('\n\n');
    rulesBuffer.writeln('$headerLevel $ruleName\n');
    rulesBuffer.writeln(details);
    rulesBuffer.writeln('$subHeaderLevel Codes\n$codes\n');
    rulesBuffer.writeln('$subHeaderLevel Examples\n$examples\n');
  }

  template = template.replaceFirst(rulesRegex, rulesBuffer.toString());

  final yamlRulesRegex = RegExp(r"{{yaml_rules\((\d*)\)}}");

  final yamlMatch = yamlRulesRegex.firstMatch(template)!;

  final indent = '  ' * int.parse(yamlMatch.group(1) ?? '0');

  final yamlRules = rules.map((r) => '$indent${r.name}: true').join('\n');

  template = template.replaceFirst(yamlRulesRegex, yamlRules);

  final outputFile = File('README.md');
  outputFile.writeAsStringSync(template);
}

DiagnosticSeverity _maxSeverity(Iterable<DiagnosticSeverity> severities) {
  return severities.reduce((a, b) {
    final aRank = a.ordinal;
    final bRank = b.ordinal;
    return aRank >= bRank ? a : b;
  });
}
