// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:grumpy_lints/src/rules/leaf_preview_must_not_use_injectables_or_navigation_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LeafPreviewMustNotUseInjectablesOrNavigationRuleTest);
  });
}

@reflectiveTest
class LeafPreviewMustNotUseInjectablesOrNavigationRuleTest
    extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = LeafPreviewMustNotUseInjectablesOrNavigationRule();
    super.setUp();
  }

  void test_direct_di_in_preview_reports() async {
    final code = r'''
class RouteContext {}

abstract class Leaf<T> {
  T preview(RouteContext ctx);
  T content(RouteContext ctx);
}

abstract class Injectable {
  bool get singelton;
}

abstract class Service {
  static T get<T>() => throw '';
}

class ApiService implements Injectable {
  @override
  bool get singelton => true;
}

class HomeLeaf extends Leaf<String> {
  @override
  String preview(RouteContext ctx) {
    final api = Service.get<ApiService>();
    return api.toString();
  }

  @override
  String content(RouteContext ctx) => 'ok';
}
''';

    await assertDiagnostics(code, [
      lint(
        code.indexOf('@override\n  String preview(RouteContext ctx) {'),
        '@override\n'
                '  String preview(RouteContext ctx) {\n'
                '    final api = Service.get<ApiService>();\n'
                '    return api.toString();\n'
                '  }'
            .length,
        name: 'leaf_preview_must_not_use_injectables_or_navigation',
      ),
    ]);
  }

  void test_transitive_di_in_preview_reports() async {
    final code = r'''
class RouteContext {}

abstract class Leaf<T> {
  T preview(RouteContext ctx);
  T content(RouteContext ctx);
}

abstract class Injectable {
  bool get singelton;
}

class ApiService implements Injectable {
  @override
  bool get singelton => true;
}

class HomeLeaf extends Leaf<String> {
  @override
  String preview(RouteContext ctx) {
    return _buildPreview();
  }

  String _buildPreview() {
    return _label();
  }

  String _label() {
    final api = ApiService();
    return api.toString();
  }

  @override
  String content(RouteContext ctx) => 'ok';
}
''';

    await assertDiagnostics(code, [
      lint(
        code.indexOf('@override\n  String preview(RouteContext ctx) {'),
        '@override\n'
                '  String preview(RouteContext ctx) {\n'
                '    return _buildPreview();\n'
                '  }'
            .length,
        name: 'leaf_preview_must_not_use_injectables_or_navigation',
      ),
    ]);
  }

  void test_direct_navigation_in_preview_reports() async {
    final code = r'''
class RouteContext {}

abstract class Leaf<T> {
  T preview(RouteContext ctx);
  T content(RouteContext ctx);
}

class RoutingService {
  void navigate(String path) {}
}

class HomeLeaf extends Leaf<String> {
  @override
  String preview(RouteContext ctx) {
    RoutingService().navigate('/login');
    return 'loading';
  }

  @override
  String content(RouteContext ctx) => 'ok';
}
''';

    await assertDiagnostics(code, [
      lint(
        code.indexOf('@override\n  String preview(RouteContext ctx) {'),
        '@override\n'
                '  String preview(RouteContext ctx) {\n'
                '    RoutingService().navigate(\'/login\');\n'
                '    return \'loading\';\n'
                '  }'
            .length,
        name: 'leaf_preview_must_not_use_injectables_or_navigation',
      ),
    ]);
  }

  void test_transitive_navigation_in_preview_reports() async {
    final code = r'''
class RouteContext {}

abstract class Leaf<T> {
  T preview(RouteContext ctx);
  T content(RouteContext ctx);
}

class RoutingService {
  void navigate(String path) {}
}

class HomeLeaf extends Leaf<String> {
  @override
  String preview(RouteContext ctx) {
    return _go();
  }

  String _go() {
    return _navigateAndBuild();
  }

  String _navigateAndBuild() {
    RoutingService().navigate('/login');
    return 'loading';
  }

  @override
  String content(RouteContext ctx) => 'ok';
}
''';

    await assertDiagnostics(code, [
      lint(
        code.indexOf('@override\n  String preview(RouteContext ctx) {'),
        '@override\n'
                '  String preview(RouteContext ctx) {\n'
                '    return _go();\n'
                '  }'
            .length,
        name: 'leaf_preview_must_not_use_injectables_or_navigation',
      ),
    ]);
  }

  void test_content_usage_is_allowed() async {
    await assertNoDiagnostics(r'''
class RouteContext {}

abstract class Leaf<T> {
  T preview(RouteContext ctx);
  T content(RouteContext ctx);
}

abstract class Service {
  static T get<T>() => throw '';
}

class RoutingService {
  void navigate(String path) {}
}

class HomeLeaf extends Leaf<String> {
  @override
  String preview(RouteContext ctx) => 'loading';

  @override
  String content(RouteContext ctx) {
    final routing = Service.get<RoutingService>();
    routing.navigate('/done');
    return 'ok';
  }
}
''');
  }
}
