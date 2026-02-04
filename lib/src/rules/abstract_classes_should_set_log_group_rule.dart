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

class AbstractClassesShouldSetLogGroupRule extends GrumpyRule {
  AbstractClassesShouldSetLogGroupRule()
    : super(
        name: 'abstract_classes_should_set_log_group',
        description:
            'Abstract classes that mix in LogMixin must override `group` '
            'to return their class name. If they extend another abstract '
            'LogMixin class, they must append their class name to '
            '`super.group` to keep group names hierarchical.',
      );

  static const LintCode code = LintCode(
    'abstract_classes_should_set_log_group',
    'Set group for {0} to {1}.',
    correctionMessage: 'Add or update group to return {1}.',
    severity: DiagnosticSeverity.INFO,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  List<Example> get examples => [
    '// Missing group override on an abstract LogMixin class.\n'
            'abstract class MyAbstractClass with LogMixin {\n'
            '  // ...\n'
            '}\n'
        .bad(),
    '// Missing group override when extending another LogMixin class.\n'
            'abstract class BaseAbstractClass with LogMixin {\n'
            '  @override\n'
            "  String get group => 'BaseAbstractClass';\n"
            '}\n\n'
            'abstract class DerivedAbstractClass extends BaseAbstractClass {\n'
            '  // ...\n'
            '}\n'
        .bad(),
    '// Group must match the abstract class name.\n'
            'abstract class MyAbstractClass with LogMixin {\n'
            '  @override\n'
            "  String get group => 'MyAbstractClass';\n"
            '}\n'
        .good(),
    '// Derived abstract classes must append to super.group.\n'
            'abstract class BaseAbstractClass with LogMixin {\n'
            '  @override\n'
            "  String get group => 'BaseAbstractClass';\n"
            '}\n\n'
            'abstract class DerivedAbstractClass extends BaseAbstractClass {\n'
            '  @override\n'
            "  String get group => '\${super.group}.DerivedAbstractClass';\n"
            '}\n'
        .good(),
  ];

  @override
  Map<DiagnosticCode, ProducerGenerator> get fixes => {
    code: SetLogGroupFix.new,
  };

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AbstractClassesShouldSetLogGroupRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !element.isAbstract) {
      return;
    }
    if (!usesLogMixin(element)) {
      return;
    }

    final className = element.displayName;
    final useSuperGroup = isAbstractLogMixinSuper(element);
    final target = findMemberTarget(node, 'group');
    if (target != null &&
        matchesGroup(
          target.expression,
          className,
          useSuperGroup: useSuperGroup,
        )) {
      return;
    }

    context.debug(
      'abstract_classes_should_set_log_group: report ${element.displayName} at '
      '${node.offset}:${node.length}',
    );
    rule.reportAtNode(
      node.namePart,
      arguments: [
        className,
        expectedGroupExpression(className, useSuperGroup: useSuperGroup),
      ],
    );
  }
}
