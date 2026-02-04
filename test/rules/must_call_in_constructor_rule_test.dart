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
    final code = r'''
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
''';
    await assertDiagnostics(code, [
      lint(
        code.indexOf('Child() {}'),
        'Child() {}'.length,
        name: 'missing_required_constructor_call',
      ),
    ]);
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
    final code = r'''
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
''';
    await assertDiagnostics(code, [
      lint(
        code.indexOf('Child() { init(); }'),
        'Child() { init(); }'.length,
        name: 'avoid_abstract_constructor_calls',
      ),
    ]);
  }

  void test_abstract_missing_call_when_not_concrete_only() async {
    final code = r'''
class MustCallInConstructor {
  final bool concreteOnly;
  final List<Type> exempt;
  const MustCallInConstructor({
    this.concreteOnly = true,
    this.exempt = const [],
  });
}

class Base {
  @MustCallInConstructor(concreteOnly: false)
  void init() {}
}

abstract class Child extends Base {
  Child() {}
}
''';
    await assertDiagnostics(code, [
      lint(
        code.indexOf('Child() {}'),
        'Child() {}'.length,
        name: 'missing_required_constructor_call',
      ),
    ]);
  }

  void test_missing_call_in_initializer_when_present() async {
    final code = r'''
class MustCallInConstructor {
  final bool concreteOnly;
  final List<Type> exempt;
  const MustCallInConstructor({
    this.concreteOnly = true,
    this.exempt = const [],
  });
}

class Initializer {
  const Initializer();
}

const initializer = Initializer();

class Base {
  @MustCallInConstructor(concreteOnly: false)
  void init() {}
}

class Child extends Base {
  Child() {
    init();
  }

  @initializer
  void initState() {}
}
''';
    final start = code.indexOf('@initializer');
    final end = code.indexOf('}', start);
    await assertDiagnostics(code, [
      lint(
        start,
        end - start + 1,
        name: 'missing_required_initializer_call',
      ),
    ]);
  }

  void test_call_present_in_initializer_no_diagnostic() async {
    final code = r'''
class MustCallInConstructor {
  final bool concreteOnly;
  final List<Type> exempt;
  const MustCallInConstructor({
    this.concreteOnly = true,
    this.exempt = const [],
  });
}

class Initializer {
  const Initializer();
}

const initializer = Initializer();

class Base {
  @MustCallInConstructor(concreteOnly: false)
  void init() {}
}

class Child extends Base {
  @initializer
  void initState() {
    init();
  }
}
''';
    await assertNoDiagnostics(code);
  }

  void test_abstract_initializer_call_concrete_only() async {
    final code = r'''
class MustCallInConstructor {
  final bool concreteOnly;
  final List<Type> exempt;
  const MustCallInConstructor({
    this.concreteOnly = true,
    this.exempt = const [],
  });
}

class Initializer {
  const Initializer();
}

const initializer = Initializer();

class Base {
  @MustCallInConstructor(concreteOnly: true)
  void init() {}
}

abstract class Child extends Base {
  @initializer
  void initState() {
    init();
  }
}
''';
    final start = code.indexOf('@initializer');
    final end = code.indexOf('}', start);
    await assertDiagnostics(code, [
      lint(
        start,
        end - start + 1,
        name: 'avoid_abstract_initializer_calls',
      ),
    ]);
  }

  void test_exempt_initializer_call_reports() async {
    final code = r'''
class MustCallInConstructor {
  final bool concreteOnly;
  final List<Type> exempt;
  const MustCallInConstructor({
    this.concreteOnly = true,
    this.exempt = const [],
  });
}

class Initializer {
  const Initializer();
}

const initializer = Initializer();

mixin InitMixin {
  @MustCallInConstructor(exempt: [NoopWidget])
  void init() {}
}

class NoopWidget with InitMixin {
  @initializer
  void initState() {
    init();
  }
}
''';
    final start = code.indexOf('@initializer');
    final end = code.indexOf('}', start);
    await assertDiagnostics(code, [
      lint(
        start,
        end - start + 1,
        name: 'avoid_exempt_initializer_calls',
      ),
    ]);
  }
}
