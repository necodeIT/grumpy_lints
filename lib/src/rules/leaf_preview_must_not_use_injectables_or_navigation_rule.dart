import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:grumpy_lints/src/log.dart';
import 'package:grumpy_lints/src/rule.dart';

class LeafPreviewMustNotUseInjectablesOrNavigationRule extends GrumpyRule {
  LeafPreviewMustNotUseInjectablesOrNavigationRule()
    : super(
        name: 'leaf_preview_must_not_use_injectables_or_navigation',
        description:
            'Leaf.preview must remain side-effect free: do not resolve/use '
            'injectables or navigation APIs in preview, including through '
            'reachable helper calls.',
      );

  static const LintCode code = LintCode(
    'leaf_preview_must_not_use_injectables_or_navigation',
    'Leaf.preview must not use DI-managed injectables or navigation APIs (found: {0}).',
    correctionMessage:
        'Move dependency resolution/navigation out of preview (for example to content or middleware).',
    severity: DiagnosticSeverity.WARNING,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  List<Example> get examples => [
    'class HomeLeaf extends Leaf<String> {\n'
            '  @override\n'
            '  String preview(RouteContext ctx) {\n'
            '    final api = Service.get<NetworkService>();\n'
            '    return api.toString();\n'
            '  }\n'
            '}\n'
        .bad(),
    'class HomeLeaf extends Leaf<String> {\n'
            '  @override\n'
            '  String preview(RouteContext ctx) => \'loading\';\n'
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
  final LeafPreviewMustNotUseInjectablesOrNavigationRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final classElement = node.declaredFragment?.element;
    if (classElement == null || !_hasTypeInHierarchy(classElement, 'Leaf')) {
      return;
    }
    final body = node.body;
    if (body is! BlockClassBody) {
      return;
    }

    final methods = <String, MethodDeclaration>{};
    MethodDeclaration? previewMethod;
    for (final member in body.members) {
      if (member is! MethodDeclaration || member.isStatic) {
        continue;
      }
      methods[member.name.lexeme] = member;
      if (member.name.lexeme == 'preview' && member.parameters != null) {
        previewMethod = member;
      }
    }
    if (previewMethod == null) {
      return;
    }
    if (!_isLeafPreviewOverride(classElement, previewMethod!)) {
      return;
    }

    final topLevelFunctions = _indexTopLevelFunctions(context.currentUnit?.unit);
    final callStack = <String>['preview'];
    final seen = <String>{};
    final result = _findForbiddenUse(
      previewMethod!.body,
      methods,
      topLevelFunctions,
      callStack,
      seen,
    );
    if (result == null) {
      return;
    }

    final path = result.path.join(' -> ');
    context.debug(
      'leaf_preview_must_not_use_injectables_or_navigation: report '
      '${classElement.displayName} at ${previewMethod!.offset}:${previewMethod.length}',
    );
    rule.reportAtNode(
      previewMethod!,
      arguments: ['$path -> ${result.sink}'],
    );
  }
}

class _ForbiddenUse {
  final String sink;
  final List<String> path;

  const _ForbiddenUse(this.sink, this.path);
}

_ForbiddenUse? _findForbiddenUse(
  FunctionBody body,
  Map<String, MethodDeclaration> classMethods,
  Map<String, FunctionDeclaration> topLevelFunctions,
  List<String> path,
  Set<String> seen,
) {
  final collector = _SinkAndCallCollector();
  body.accept(collector);
  if (collector.sink != null) {
    return _ForbiddenUse(collector.sink!, List.of(path));
  }

  for (final call in collector.calls) {
    final key = '${call.kind}:${call.name}';
    if (!seen.add(key)) {
      continue;
    }

    if (call.kind == _CallKind.classMethod) {
      final method = classMethods[call.name];
      if (method == null || method.body == body) {
        continue;
      }
      path.add(call.name);
      final hit = _findForbiddenUse(
        method.body,
        classMethods,
        topLevelFunctions,
        path,
        seen,
      );
      path.removeLast();
      if (hit != null) {
        return hit;
      }
      continue;
    }

    final function = topLevelFunctions[call.name];
    if (function == null || function.functionExpression.body == body) {
      continue;
    }
    path.add(call.name);
    final hit = _findForbiddenUse(
      function.functionExpression.body,
      classMethods,
      topLevelFunctions,
      path,
      seen,
    );
    path.removeLast();
    if (hit != null) {
      return hit;
    }
  }

  return null;
}

class _SinkAndCallCollector extends RecursiveAstVisitor<void> {
  String? sink;
  final List<_CallRef> calls = [];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (sink != null) {
      return;
    }
    final createdType = node.constructorName.type.type;
    if (_isInjectableType(createdType)) {
      sink = 'constructing injectable ${_typeLabel(createdType)}';
      return;
    }
    if (_isRoutingType(createdType)) {
      sink = 'constructing routing service';
      return;
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (sink != null) {
      return;
    }
    final methodName = node.methodName.name;
    if (_isDiAccessor(node)) {
      sink = 'DI access via $methodName';
      return;
    }

    final receiverType = node.realTarget?.staticType;
    if (_isInjectableType(receiverType)) {
      sink = 'calling $methodName on Injectable';
      return;
    }
    if (methodName == 'navigate' && _isRoutingType(receiverType)) {
      sink = 'navigation via RoutingService.navigate';
      return;
    }

    if (node.realTarget == null || node.realTarget is ThisExpression) {
      calls.add(_CallRef(_CallKind.classMethod, methodName));
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    final function = node.function;
    if (function is SimpleIdentifier) {
      calls.add(_CallRef(_CallKind.topLevelFunction, function.name));
    }
    super.visitFunctionExpressionInvocation(node);
  }
}

enum _CallKind { classMethod, topLevelFunction }

class _CallRef {
  final _CallKind kind;
  final String name;

  const _CallRef(this.kind, this.name);
}

Map<String, FunctionDeclaration> _indexTopLevelFunctions(CompilationUnit? unit) {
  if (unit == null) {
    return const {};
  }
  final index = <String, FunctionDeclaration>{};
  for (final declaration in unit.declarations) {
    if (declaration is! FunctionDeclaration) {
      continue;
    }
    index[declaration.name.lexeme] = declaration;
  }
  return index;
}

bool _isLeafPreviewOverride(
  ClassElement classElement,
  MethodDeclaration method,
) {
  if (method.name.lexeme != 'preview') {
    return false;
  }
  if (!_hasTypeInHierarchy(classElement, 'Leaf')) {
    return false;
  }
  final parameters = method.parameters?.parameters;
  if (parameters == null || parameters.length != 1) {
    return false;
  }
  return true;
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

bool _isDiAccessor(MethodInvocation node) {
  final methodName = node.methodName.name;
  if (methodName != 'get' &&
      methodName != 'getAsync' &&
      methodName != 'getAll' &&
      methodName != 'getAllAsync') {
    return false;
  }
  final target = node.target;
  if (target is SimpleIdentifier) {
    return target.name == 'Service' ||
        target.name == 'Datasource' ||
        target.name == 'Repo';
  }
  if (target is PrefixedIdentifier) {
    return target.identifier.name == 'Service' ||
        target.identifier.name == 'Datasource' ||
        target.identifier.name == 'Repo' ||
        (target.prefix.name == 'GetIt' && target.identifier.name == 'instance');
  }
  if (target is PropertyAccess) {
    final base = target.target;
    return base is SimpleIdentifier &&
        base.name == 'GetIt' &&
        target.propertyName.name == 'instance';
  }
  final targetType = node.realTarget?.staticType;
  return _isTypeNamed(targetType, 'GetIt');
}

bool _isInjectableType(DartType? type) {
  return _isTypeNamed(type, 'Injectable') || _isSubtypeNamed(type, 'Injectable');
}

bool _isRoutingType(DartType? type) {
  return _isTypeNamed(type, 'RoutingService') ||
      _isSubtypeNamed(type, 'RoutingService');
}

bool _isTypeNamed(DartType? type, String name) {
  if (type is! InterfaceType) {
    return false;
  }
  return type.element.displayName == name;
}

bool _isSubtypeNamed(DartType? type, String name) {
  if (type is! InterfaceType) {
    return false;
  }
  for (final supertype in type.allSupertypes) {
    if (supertype.element.displayName == name) {
      return true;
    }
  }
  return false;
}

String _typeLabel(DartType? type) {
  if (type is InterfaceType) {
    return type.element.displayName;
  }
  return 'unknown';
}
