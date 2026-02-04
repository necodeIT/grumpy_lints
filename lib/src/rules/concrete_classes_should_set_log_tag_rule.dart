// ignore: implementation_imports
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:grumpy_lints/src/fixes/logging_fixes.dart';
import 'package:grumpy_lints/src/log.dart';
import 'package:grumpy_lints/src/rule.dart';
import 'package:grumpy_lints/src/rules/logging_utils.dart';

class ConcreteClassesShouldSetLogTagRule extends GrumpyRule {
  ConcreteClassesShouldSetLogTagRule()
    : super(
        name: 'concrete_classes_should_set_log_tag',
        description:
            'Concrete (non-abstract) classes that mix in LogMixin must '
            'override `logTag` to return their own class name. This applies '
            'even when inheriting from another LogMixin class so each class '
            'logs with a specific tag.',
      );

  static const LintCode code = LintCode(
    'concrete_classes_should_set_log_tag',
    'Set logTag for {0} to {1}.',
    correctionMessage: 'Add or update logTag to return {1}.',
    severity: DiagnosticSeverity.INFO,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  List<Example> get examples => [
    '// Missing logTag override on a concrete LogMixin class.\n'
            'class MyConcreteClass with LogMixin {\n'
            '  // ...\n'
            '}\n'
        .bad(),
    '// Concrete class must use its own class name as logTag.\n'
            'class MyConcreteClass with LogMixin {\n'
            '  @override\n'
            "  String get logTag => 'MyConcreteClass';\n"
            '}\n'
        .good(),
    '// Missing logTag override when extending another LogMixin class.\n'
            'abstract class BaseClass with LogMixin {\n'
            '  @override\n'
            "  String get group => 'BaseClass';\n"
            '}\n\n'
            'class DerivedConcreteClass extends BaseClass {\n'
            '  // ...\n'
            '}\n'
        .bad(),
    '// Derived concrete classes must override logTag too.\n'
            'abstract class BaseClass with LogMixin {\n'
            '  @override\n'
            "  String get group => 'BaseClass';\n"
            '}\n\n'
            'class DerivedConcreteClass extends BaseClass {\n'
            '  @override\n'
            "  String get logTag => 'DerivedConcreteClass';\n"
            '}\n'
        .good(),
  ];

  @override
  Map<DiagnosticCode, ProducerGenerator> get fixes => {code: SetLogTagFix.new};

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final ConcreteClassesShouldSetLogTagRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || element.isAbstract) {
      return;
    }
    if (!usesLogMixin(element)) {
      return;
    }

    final className = element.displayName;
    final target = findMemberTarget(node, 'logTag');
    if (target != null && matchesLogTag(target.expression, className)) {
      return;
    }

    context.debug(
      'concrete_classes_should_set_log_tag: report ${element.displayName} at '
      '${node.offset}:${node.length}',
    );
    rule.reportAtNode(
      node.namePart,
      arguments: [className, expectedLogTagExpression(className)],
    );
  }
}
