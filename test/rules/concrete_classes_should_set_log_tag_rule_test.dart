// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:grumpy_lints/src/rules/concrete_classes_should_set_log_tag_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConcreteClassesShouldSetLogTagRuleTest);
  });
}

@reflectiveTest
class ConcreteClassesShouldSetLogTagRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = ConcreteClassesShouldSetLogTagRule();
    super.setUp();
  }

  void test_missing_log_tag_on_concrete_class() async {
    final code = r'''
mixin class LogMixin {
  String get logTag => '';
  String get group => '';
}

class MyConcreteClass with LogMixin {
}
''';

    await assertDiagnostics(code, [
      lint(code.indexOf('MyConcreteClass'), 'MyConcreteClass'.length),
    ]);
  }

  void test_missing_log_tag_on_concrete_subclass() async {
    final code = r'''
mixin class LogMixin {
  String get logTag => '';
  String get group => '';
}

abstract class Base with LogMixin {
  @override
  String get logTag => 'Base';
}

class Child extends Base {
}
''';

    await assertDiagnostics(code, [
      lint(code.indexOf('Child'), 'Child'.length),
    ]);
  }

  void test_incorrect_log_tag_value() async {
    final code = r'''
mixin class LogMixin {
  String get logTag => '';
  String get group => '';
}

class WrongTag with LogMixin {
  @override
  String get logTag => 'NotWrongTag';
}
''';

    await assertDiagnostics(code, [
      lint(code.indexOf('WrongTag'), 'WrongTag'.length),
    ]);
  }

  void test_log_tag_set_ok() async {
    final code = r'''
mixin class LogMixin {
  String get logTag => '';
  String get group => '';
}

class RightTag with LogMixin {
  @override
  String get logTag => 'RightTag';
}
''';

    await assertNoDiagnostics(code);
  }

  void test_abstract_class_ignored() async {
    final code = r'''
mixin class LogMixin {
  String get logTag => '';
  String get group => '';
}

abstract class AbstractThing with LogMixin {
}
''';

    await assertNoDiagnostics(code);
  }
}
