// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:grumpy_lints/src/rules/abstract_classes_should_set_log_group_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AbstractClassesShouldSetLogGroupRuleTest);
  });
}

@reflectiveTest
class AbstractClassesShouldSetLogGroupRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AbstractClassesShouldSetLogGroupRule();
    super.setUp();
  }

  void test_missing_group_on_abstract_class() async {
    final code = r'''
mixin class LogMixin {
  String get logTag => '';
  String get group => '';
}

abstract class MyAbstractClass with LogMixin {
}
''';

    await assertDiagnostics(code, [
      lint(code.indexOf('MyAbstractClass'), 'MyAbstractClass'.length),
    ]);
  }

  void test_missing_group_on_abstract_subclass() async {
    final code = r'''
mixin class LogMixin {
  String get logTag => '';
  String get group => '';
}

abstract class BaseAbstractClass with LogMixin {
  @override
  String get group => 'BaseAbstractClass';
}

abstract class DerivedAbstractClass extends BaseAbstractClass {
}
''';

    await assertDiagnostics(code, [
      lint(code.indexOf('DerivedAbstractClass'), 'DerivedAbstractClass'.length),
    ]);
  }

  void test_group_set_ok() async {
    final code = r'''
mixin class LogMixin {
  String get logTag => '';
  String get group => '';
}

abstract class MyAbstractClass with LogMixin {
  @override
  String get group => 'MyAbstractClass';
}
''';

    await assertNoDiagnostics(code);
  }

  void test_group_set_with_super_ok() async {
    final code = r'''
mixin class LogMixin {
  String get logTag => '';
  String get group => '';
}

abstract class BaseAbstractClass with LogMixin {
  @override
  String get group => 'BaseAbstractClass';
}

abstract class DerivedAbstractClass extends BaseAbstractClass {
  @override
  String get group => '${super.group}.DerivedAbstractClass';
}
''';

    await assertNoDiagnostics(code);
  }

  void test_concrete_class_ignored() async {
    final code = r'''
mixin class LogMixin {
  String get logTag => '';
  String get group => '';
}

class ConcreteClass with LogMixin {
}
''';

    await assertNoDiagnostics(code);
  }
}
