// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:grumpy_lints/src/rules/must_call_in_constructor_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MustCallInConstructorRuleTest);
  });
}

@reflectiveTest
class MustCallInConstructorRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = MustCallInConstructorRule();
    super.setUp();
  }

  void test_missing_call_in_constructor() async {
    await assertDiagnostics(
      r'''
class MustCallInConstructor {
  final bool concreteOnly;
  const MustCallInConstructor({this.concreteOnly = true});
}

const mustCallInConstructor = MustCallInConstructor();

class Base {
  @mustCallInConstructor
  void init() {}
}

class Child extends Base {
  Child() {}
}
''',
      [lint(262, 10, name: 'missing_required_constructor_call')],
    );
  }

  void test_call_present_no_diagnostic() async {
    await assertNoDiagnostics(r'''
class MustCallInConstructor {
  final bool concreteOnly;
  const MustCallInConstructor({this.concreteOnly = true});
}

const mustCallInConstructor = MustCallInConstructor();

class Base {
  @mustCallInConstructor
  void init() {}
}

class Child extends Base {
  Child() { init(); }
}
''');
  }

  void test_abstract_constructor_call_concrete_only() async {
    await assertDiagnostics(
      r'''
class MustCallInConstructor {
  final bool concreteOnly;
  const MustCallInConstructor({this.concreteOnly = true});
}

class Base {
  @MustCallInConstructor(concreteOnly: true)
  void init() {}
}

abstract class Child extends Base {
  Child() { init(); }
}
''',
      [lint(235, 19, name: 'avoid_abstract_constructor_calls')],
    );
  }

  void test_abstract_missing_call_when_not_concrete_only() async {
    await assertDiagnostics(
      r'''
class MustCallInConstructor {
  final bool concreteOnly;
  const MustCallInConstructor({this.concreteOnly = true});
}

class Base {
  @MustCallInConstructor(concreteOnly: false)
  void init() {}
}

abstract class Child extends Base {
  Child() {}
}
''',
      [lint(236, 10, name: 'missing_required_constructor_call')],
    );
  }
}
