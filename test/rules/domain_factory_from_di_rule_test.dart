// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:grumpy_lints/src/rules/domain_factory_from_di_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DomainFactoryFromDiRuleTest);
  });
}

@reflectiveTest
class DomainFactoryFromDiRuleTest extends AnalysisRuleTest {
  String _testFileName = 'src/module/domain/services/user_service.dart';

  @override
  String get testFileName => _testFileName;

  @override
  void setUp() {
    rule = DomainFactoryFromDiRule();
    super.setUp();
  }

  void test_service_missing_factory() async {
    _testFileName = 'src/module/domain/services/user_service.dart';

    final code = r'''
abstract class Service {
  static T get<T>() => throw '';
}

abstract class UserService extends Service {}
''';

    await assertDiagnostics(code, [
      lint(
        code.indexOf('UserService'),
        'UserService'.length,
        name: 'domain_factory_from_di_missing_factory',
      ),
    ]);
  }

  void test_service_with_factory() async {
    _testFileName = 'src/module/domain/services/user_service.dart';

    final code = r'''
abstract class Service {
  static T get<T>() => throw '';
}

abstract class UserService extends Service {
  /// Returns the DI-registered implementation of [UserService].
  factory UserService() {
    return Service.get<UserService>();
  }
}
''';

    await assertNoDiagnostics(code);
  }

  void test_datasource_missing_factory() async {
    _testFileName = 'src/module/domain/datasources/user_datasource.dart';

    final code = r'''
abstract class Datasource {}

abstract class UserDatasource extends Datasource {}
''';

    await assertDiagnostics(code, [
      lint(
        code.indexOf('UserDatasource'),
        'UserDatasource'.length,
        name: 'domain_factory_from_di_missing_factory',
      ),
    ]);
  }

  void test_base_class_is_exempt() async {
    _testFileName = 'src/module/domain/services/service.dart';

    final code = r'''
abstract class Service {}
''';

    await assertNoDiagnostics(code);
  }

  void test_non_domain_path_is_exempt() async {
    _testFileName = 'src/module/infra/services/user_service.dart';

    final code = r'''
abstract class Service {}

abstract class UserService extends Service {}
''';

    await assertNoDiagnostics(code);
  }
}
