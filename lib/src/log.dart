import 'dart:io';

import 'package:analyzer/analysis_rule/rule_context.dart';

enum GrumpyLogSeverity { debug, info, warning, error }

extension GrumpyLog on RuleContext {
  static const String logFileName = 'grumpy_lints.log';

  void debug(String message) {
    _write(this, GrumpyLogSeverity.debug, message);
  }

  void info(String message) {
    _write(this, GrumpyLogSeverity.info, message);
  }

  void warning(String message) {
    _write(this, GrumpyLogSeverity.warning, message);
  }

  void error(String message) {
    _write(this, GrumpyLogSeverity.error, message);
  }

  static void _write(
    RuleContext context,
    GrumpyLogSeverity severity,
    String message,
  ) {
    final timestamp = DateTime.now().toIso8601String();
    final line = '[${severity.name.toUpperCase()}] $timestamp $message';
    if (_shouldPrintToStdout()) {
      _printLine(severity, line);
      return;
    }

    final root = _findWorkspaceRoot(context);
    final file = File(_joinPath(root, logFileName));
    try {
      file.writeAsStringSync(
        '$line${Platform.lineTerminator}',
        mode: FileMode.append,
        flush: true,
      );
    } on FileSystemException {
      _printLine(severity, line);
    }
  }

  static String _findWorkspaceRoot(RuleContext context) {
    final packageRoot = context.package?.root.path;
    if (packageRoot != null && packageRoot.isNotEmpty) {
      return packageRoot;
    }
    return context.definingUnit.file.parent.path;
  }

  static String _joinPath(String root, String file) {
    final separator = Platform.pathSeparator;
    if (root.endsWith(separator)) {
      return '$root$file';
    }
    return '$root$separator$file';
  }

  static bool _shouldPrintToStdout() {
    final env = Platform.environment;
    if (env['GRUMPY_LINTS_LOG_STDOUT'] == '1' ||
        env['GRUMPY_LINTS_LOG_STDOUT']?.toLowerCase() == 'true') {
      return true;
    }
    return env.containsKey('DART_TEST') ||
        env.containsKey('FLUTTER_TEST') ||
        env.containsKey('UNIT_TEST');
  }

  static void _printLine(GrumpyLogSeverity severity, String line) {
    if (severity == GrumpyLogSeverity.error ||
        severity == GrumpyLogSeverity.warning) {
      stderr.writeln(line);
      return;
    }
    stdout.writeln(line);
  }
}
