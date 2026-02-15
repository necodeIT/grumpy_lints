import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:grumpy_lints/src/log.dart';
import 'package:grumpy_lints/src/rule.dart';

class LifecycleMixinRequiresSingletonRule extends GrumpyRule {
  LifecycleMixinRequiresSingletonRule()
    : super(
        name: 'lifecycle_mixin_requires_singleton',
        description:
            'Classes that combine Injectable and LifecycleMixin must resolve '
            'as singletons by returning true from singelton.',
      );

  static const LintCode code = LintCode(
    'lifecycle_mixin_requires_singleton',
    'Classes using both Injectable and LifecycleMixin must return true from singelton.',
    correctionMessage: 'Override singelton to return true.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  List<Example> get examples => [
    'class RoutingService with LifecycleMixin implements Injectable {\n'
            '  @override\n'
            '  bool get singelton => false;\n'
            '}\n'
        .bad(),
    'class RoutingService with LifecycleMixin implements Injectable {\n'
            '  @override\n'
            '  bool get singelton => true;\n'
            '}\n'
        .good(),
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LifecycleMixinRequiresSingletonRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) {
      return;
    }
    if (!_hasTypeInHierarchy(element, 'Injectable')) {
      return;
    }
    if (!_hasTypeInHierarchy(element, 'LifecycleMixin')) {
      return;
    }
    if (_hasTrueSingletonGetter(node)) {
      return;
    }

    context.debug(
      'lifecycle_mixin_requires_singleton: report ${element.displayName} at '
      '${node.offset}:${node.length}',
    );
    rule.reportAtNode(node.namePart);
  }
}

bool _hasTypeInHierarchy(ClassElement element, String typeName) {
  if (element.displayName == typeName) {
    return true;
  }
  for (final supertype in element.allSupertypes) {
    if (supertype.element.displayName == typeName) {
      return true;
    }
  }
  return false;
}

bool _hasTrueSingletonGetter(ClassDeclaration node) {
  final body = node.body;
  if (body is! BlockClassBody) {
    return false;
  }
  for (final member in body.members) {
    if (member is! MethodDeclaration) {
      continue;
    }
    if (member.isGetter != true || member.name.lexeme != 'singelton') {
      continue;
    }
    final expressionBody = member.body;
    if (expressionBody is ExpressionFunctionBody) {
      final expression = expressionBody.expression;
      return expression is BooleanLiteral && expression.value;
    }
    if (expressionBody is BlockFunctionBody) {
      for (final statement in expressionBody.block.statements) {
        if (statement is! ReturnStatement) {
          continue;
        }
        final expression = statement.expression;
        return expression is BooleanLiteral && expression.value;
      }
    }
  }
  return false;
}
