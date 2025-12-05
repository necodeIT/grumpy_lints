import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:modular_foundation_lints/src/lifycycle/avoid_abstract_initialize_calls.dart';
import 'package:modular_foundation_lints/src/lifycycle/call_initialize_in_constructor.dart';
import 'package:modular_foundation_lints/src/lifycycle/call_initialize_last.dart';
import 'package:modular_foundation_lints/src/lifycycle/constructor_must_call_install_hooks.dart';
import 'package:modular_foundation_lints/src/utils/rule.dart';

// This is the entrypoint of our custom linter
PluginBase createPlugin() => ModularLinter();

/// A plugin class is used to list all the assists/lints defined by a plugin.
class ModularLinter extends PluginBase {
  /// We list all the custom warnings/infos/errors
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => rules;
}

const List<DocumentedDartLintRule> rules = [
  CallInitializeInConstructor(),
  AvoidAbstractInitializeCalls(),
  CallInitializeLast(),
  ConstructorMustInstallHooks(),
];
