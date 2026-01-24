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
      [lint(263, 10)],
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
      [lint(236, 19, name: 'must_call_in_constructor_in_abstract')],
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
      [lint(237, 10)],
    );
  }
}
