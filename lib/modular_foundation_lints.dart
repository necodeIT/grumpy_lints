import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:modular_foundation_lints/src/lifecycle_lints.dart';

// This is the entrypoint of our custom linter
PluginBase createPlugin() => ModularLinter();

/// A plugin class is used to list all the assists/lints defined by a plugin.
class ModularLinter extends PluginBase {
  /// We list all the custom warnings/infos/errors
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    ConstructorMustCallInitialize(),
    ConstructorMustInstallHooks(),
  ];
}
