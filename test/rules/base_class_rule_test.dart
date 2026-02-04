// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:grumpy_lints/src/rules/base_class_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BaseClassRuleTest);
  });
}

@reflectiveTest
class BaseClassRuleTest extends AnalysisRuleTest {
  String _testFileName = 'src/module/domain/services/user_service.dart';

  @override
  String get testFileName => _testFileName;

  @override
  void setUp() {
    rule = BaseClassRule();
    super.setUp();
  }

  void test_valid_subclass() async {
    _testFileName = 'src/module/domain/services/user_service.dart';
    _addBaseClassFile();

    final code = r'''
import 'package:test/src/module/domain/services/service.dart';

abstract class UserService extends Service {}
''';

    await assertNoDiagnostics(code);
  }

  void test_invalid_layer() async {
    _testFileName = 'src/module/presentation/services/user_service.dart';
    _addBaseClassFile();

    final code = r'''
import 'package:test/src/module/domain/services/service.dart';

abstract class UserService extends Service {}
''';

    await assertDiagnostics(code, [
      lint(
        code.indexOf('UserService'),
        'UserService'.length,
        name: 'base_class_invalid_layer',
      ),
    ]);
  }

  void test_missing_suffix() async {
    _testFileName = 'src/module/domain/services/user_manager.dart';
    _addBaseClassFile();

    final code = r'''
import 'package:test/src/module/domain/services/service.dart';

abstract class UserManager extends Service {}
''';

    await assertDiagnostics(code, [
      lint(
        code.indexOf('UserManager'),
        'UserManager'.length,
        name: 'base_class_missing_suffix',
      ),
    ]);
  }

  void test_missing_suffix_not_required_when_force_suffix_false() async {
    _testFileName = 'src/module/domain/services/user_manager.dart';
    _addBaseClassFile(forceSuffix: false);

    final code = r'''
import 'package:test/src/module/domain/services/service.dart';

abstract class UserManager extends Service {}
''';

    await assertNoDiagnostics(code);
  }

  void test_wrong_directory() async {
    _testFileName = 'src/module/domain/user_service.dart';
    _addBaseClassFile();

    final code = r'''
import 'package:test/src/module/domain/services/service.dart';

abstract class UserService extends Service {}
''';

    await assertDiagnostics(code, [
      lint(
        code.indexOf('UserService'),
        'UserService'.length,
        name: 'base_class_wrong_directory',
      ),
    ]);
  }

  void test_wrong_file_name() async {
    _testFileName = 'src/module/domain/services/userService.dart';
    _addBaseClassFile();

    final code = r'''
import 'package:test/src/module/domain/services/service.dart';

abstract class UserService extends Service {}
''';

    await assertDiagnostics(code, [
      lint(
        code.indexOf('UserService'),
        'UserService'.length,
        name: 'base_class_wrong_file_name',
      ),
    ]);
  }

  void test_extra_class_in_file() async {
    _testFileName = 'src/module/domain/services/user_service.dart';
    _addBaseClassFile();

    final code = r'''
import 'package:test/src/module/domain/services/service.dart';

abstract class UserService extends Service {}

class Helper {}
''';

    await assertDiagnostics(code, [
      lint(
        code.indexOf('UserService'),
        'UserService'.length,
        name: 'base_class_extra_class',
      ),
      lint(
        code.indexOf('Helper'),
        'Helper'.length,
        name: 'base_class_missing_extension',
      ),
    ]);
  }

  void test_missing_extension() async {
    _testFileName = 'src/module/domain/services/user_service.dart';
    _addBaseClassFile();

    final code = r'''
import 'package:test/src/module/domain/services/service.dart';

abstract class UserService {}

void takesService(Service service) {}
''';

    await assertDiagnostics(code, [
      lint(
        code.indexOf('UserService'),
        'UserService'.length,
        name: 'base_class_missing_extension',
      ),
    ]);
  }

  void _addBaseClassFile({bool forceSuffix = true}) {
    newFile('$testPackageLibPath/src/module/domain/services/service.dart', '''
enum LayerType { infra, domain, presentation }

class BaseClass {
  final Set<LayerType> allowedLayers;
  final String? typeDirectory;
  final bool forceSuffix;

  const BaseClass({
    this.allowedLayers = const {LayerType.domain},
    this.typeDirectory,
    this.forceSuffix = true,
  });
}

@BaseClass(
  allowedLayers: {LayerType.domain},
  typeDirectory: 'services',
  forceSuffix: $forceSuffix,
)
abstract class Service {}
''');
  }
}
