import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:grumpy_lints/src/rule.dart';
import 'package:grumpy_lints/src/rules/abstract_classes_should_set_log_group_rule.dart';
import 'package:grumpy_lints/src/rules/base_class_rule.dart';
import 'package:grumpy_lints/src/rules/concrete_classes_should_set_log_tag_rule.dart';
import 'package:grumpy_lints/src/rules/domain_factory_from_di_rule.dart';
import 'package:grumpy_lints/src/rules/prefer_domain_di_factory_rule.dart';
import 'package:grumpy_lints/src/rules/must_call_in_constructor_rule.dart';

final plugin = GrumpyLints();

class GrumpyLints extends Plugin {
  @override
  String get name => 'grumpy';

  static List<GrumpyRule> warnings = [];
  static List<GrumpyRule> errors = [
    MustCallInConstructorRule(),
    AbstractClassesShouldSetLogGroupRule(),
    ConcreteClassesShouldSetLogTagRule(),
    BaseClassRule(),
    DomainFactoryFromDiRule(),
    PreferDomainDiFactoryRule(),
  ];

  @override
  void register(PluginRegistry registry) {
    for (var rule in warnings) {
      registry.registerWarningRule(rule);
      rule.registerFixes(registry);
    }
    for (var rule in errors) {
      registry.registerLintRule(rule);
      rule.registerFixes(registry);
    }
  }
}
