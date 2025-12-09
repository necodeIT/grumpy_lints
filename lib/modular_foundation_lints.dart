import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:modular_foundation_lints/src/architecture/require_suffix.dart';
import 'package:modular_foundation_lints/src/architecture/require_super_class.dart';
import 'package:modular_foundation_lints/src/lifycycle/avoid_abstract_initialize_calls.dart';
import 'package:modular_foundation_lints/src/lifycycle/call_initialize_in_constructor.dart';
import 'package:modular_foundation_lints/src/lifycycle/call_initialize_last.dart';
import 'package:modular_foundation_lints/src/lifycycle/constructor_must_call_install_hooks.dart';
import 'package:modular_foundation_lints/src/utils/const.dart';
import 'package:modular_foundation_lints/src/utils/rule.dart';

// This is the entrypoint of our custom linter
PluginBase createPlugin() => ModularLinter();

/// A plugin class is used to list all the assists/lints defined by a plugin.
class ModularLinter extends PluginBase {
  /// We list all the custom warnings/infos/errors
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => rules;
}

final List<DocumentedDartLintRule> rules = [
  CallInitializeInConstructor(),
  AvoidAbstractInitializeCalls(),
  CallInitializeLast(),
  ConstructorMustInstallHooks(),

  // Architecture rules

  // Suffix rules
  RequireSuffix(layer: 'services', suffix: kServiceClass),
  RequireSuffix(layer: 'datasources', suffix: kDatasourceClass),
  RequireSuffix(layer: 'models', suffix: kModelClass, enabledByDefault: false),
  RequireSuffix(layer: 'repositories', suffix: kRepoClass),
  RequireSuffix(layer: 'views', suffix: kViewClass),
  RequireSuffix(layer: 'guards', suffix: kGuardClass),

  // Superclass rules
  RequireSuperClass(layer: 'services', superClassName: kServiceClass),
  RequireSuperClass(layer: 'datasources', superClassName: kDatasourceClass),
  RequireSuperClass(layer: 'models', superClassName: kModelClass),
  RequireSuperClass(layer: 'repositories', superClassName: kRepoClass),
  RequireSuperClass(layer: 'views', superClassName: kViewClass),
  RequireSuperClass(layer: 'guards', superClassName: kGuardClass),
];
