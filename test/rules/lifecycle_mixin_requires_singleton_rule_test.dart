// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:grumpy_lints/src/rules/lifecycle_mixin_requires_singleton_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LifecycleMixinRequiresSingletonRuleTest);
  });
}

@reflectiveTest
class LifecycleMixinRequiresSingletonRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = LifecycleMixinRequiresSingletonRule();
    super.setUp();
  }

  void test_injectable_with_lifecycle_and_false_singleton_reports() async {
    final code = r'''
abstract class Injectable {
  bool get singelton;
}

mixin LifecycleMixin {}

class Worker with LifecycleMixin implements Injectable {
  @override
  bool get singelton => false;
}
''';

    await assertDiagnostics(code, [
      lint(
        code.indexOf('Worker'),
        'Worker'.length,
        name: 'lifecycle_mixin_requires_singleton',
      ),
    ]);
  }

  void test_injectable_with_lifecycle_and_true_singleton_is_allowed() async {
    await assertNoDiagnostics(r'''
abstract class Injectable {
  bool get singelton;
}

mixin LifecycleMixin {}

class Worker with LifecycleMixin implements Injectable {
  @override
  bool get singelton => true;
}
''');
  }

  void test_injectable_without_lifecycle_is_allowed() async {
    await assertNoDiagnostics(r'''
abstract class Injectable {
  bool get singelton;
}

class Worker implements Injectable {
  @override
  bool get singelton => false;
}
''');
  }
}
