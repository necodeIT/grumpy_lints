// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:grumpy_lints/src/rules/prefer_domain_di_factory_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferDomainDiFactoryRuleTest);
  });
}

@reflectiveTest
class PreferDomainDiFactoryRuleTest extends AnalysisRuleTest {
  String _testFileName = 'src/module/presentation/screens/screen_renderer.dart';

  @override
  String get testFileName => _testFileName;

  @override
  void setUp() {
    rule = PreferDomainDiFactoryRule();
    super.setUp();
  }

  void test_service_get_in_presentation_is_reported() async {
    _testFileName = 'src/module/presentation/screens/screen_renderer.dart';
    _addDomainFiles();

    final code = r'''
import 'package:test/src/module/domain/services/service.dart';
import 'package:test/src/module/domain/services/routing_service.dart';

final routing = Service.get<RoutingService>();
''';

    await assertDiagnostics(code, [
      lint(
        code.indexOf('get'),
        'get'.length,
        name: 'prefer_domain_di_factory',
      ),
    ]);
  }

  void test_datasource_get_in_infra_is_reported() async {
    _testFileName = 'src/module/infra/services/analytics_service.dart';
    _addDomainFiles();

    final code = r'''
import 'package:test/src/module/domain/datasources/datasource.dart';
import 'package:test/src/module/domain/datasources/user_datasource.dart';

final users = Datasource.get<UserDatasource>();
''';

    await assertDiagnostics(code, [
      lint(
        code.indexOf('get'),
        'get'.length,
        name: 'prefer_domain_di_factory',
      ),
    ]);
  }

  void test_domain_layer_is_exempt() async {
    _testFileName = 'src/module/domain/services/routing_service.dart';
    _addDomainFiles();

    final code = r'''
abstract class Service {
  static T get<T>() => throw '';
}

abstract class RoutingService extends Service {}

final routing = Service.get<RoutingService>();
''';

    await assertNoDiagnostics(code);
  }

  void test_non_domain_type_is_exempt() async {
    _testFileName = 'src/module/presentation/screens/screen_renderer.dart';
    _addDomainFiles();

    final code = r'''
import 'package:test/src/module/domain/services/service.dart';

class Logger {}

final logger = Service.get<Logger>();
''';

    await assertNoDiagnostics(code);
  }

  void _addDomainFiles() {
    newFile('$testPackageLibPath/src/module/domain/services/service.dart', r'''
abstract class Service {
  static T get<T>() => throw '';
}
''');

    newFile(
      '$testPackageLibPath/src/module/domain/services/routing_service.dart',
      r'''
import 'package:test/src/module/domain/services/service.dart';

abstract class RoutingService extends Service {}
''',
    );

    newFile(
      '$testPackageLibPath/src/module/domain/datasources/datasource.dart',
      r'''
abstract class Datasource {
  static T get<T>() => throw '';
}
''',
    );

    newFile(
      '$testPackageLibPath/src/module/domain/datasources/user_datasource.dart',
      r'''
import 'package:test/src/module/domain/datasources/datasource.dart';

abstract class UserDatasource extends Datasource {}
''',
    );
  }
}
