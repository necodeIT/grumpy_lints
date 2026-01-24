// ignore: implementation_imports
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:grumpy_lints/src/fixes/logging_fixes.dart';
import 'package:grumpy_lints/src/rule.dart';
import 'package:grumpy_lints/src/rules/logging_utils.dart';

class ConcreteClassesShouldSetLogTagRule extends GrumpyRule {
  ConcreteClassesShouldSetLogTagRule()
    : super(
        name: 'concrete_classes_should_set_log_tag',
        description:
            'Concrete classes using LogMixin must override logTag '
            'with their class name.',
      );

  static const LintCode code = LintCode(
    'concrete_classes_should_set_log_tag',
    'Set logTag for {0} to {1}.',
    correctionMessage: 'Add or update logTag to return {1}.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  List<Example> get examples => [
    'class MyConcreteClass with LogMixin {\n}\n'.bad(),
    'class MyConcreteClass with LogMixin {\n'
            '  @override\n'
            '  String get logTag => \'MyConcreteClass\';\n'
            '}\n'
        .good(),
  ];

  @override
  Map<DiagnosticCode, ProducerGenerator> get fixes =>
      {code: SetLogTagFix.new};

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final ConcreteClassesShouldSetLogTagRule rule;

  _Visitor(this.rule);

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

    rule.reportAtNode(
      node.namePart,
      arguments: [className, expectedLogTagExpression(className)],
    );
  }
}
