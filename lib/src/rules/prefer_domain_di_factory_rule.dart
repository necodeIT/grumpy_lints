// ignore: implementation_imports
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:grumpy_lints/src/fixes/prefer_domain_di_factory_fixes.dart';
import 'package:grumpy_lints/src/log.dart';
import 'package:grumpy_lints/src/rule.dart';

class PreferDomainDiFactoryRule extends GrumpyRule {
  PreferDomainDiFactoryRule()
    : super(
        name: 'prefer_domain_di_factory',
        description:
            'Prefer using the domain contract factory constructor over direct '
            'DI access (Service.get/Datasource.get) outside the domain layer.',
      );

  static const LintCode code = LintCode(
    'prefer_domain_di_factory',
    'Prefer using {0}() instead of {1}.get for domain {2}.',
    correctionMessage:
        'Use the domain factory constructor (e.g., {0}()) instead.',
    severity: DiagnosticSeverity.INFO,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  List<Example> get examples => [
    'final routing = Service.get<RoutingService>();\n'.bad(),
    'final routing = RoutingService();\n'.good(),
  ];

  @override
  Map<DiagnosticCode, ProducerGenerator> get fixes => {
    code: PreferDomainDiFactoryFix.new,
  };

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodInvocation(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferDomainDiFactoryRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isTestFile(context, context.currentUnit?.file.path)) {
      return;
    }

    if (node.methodName.name != 'get') {
      return;
    }

    final accessor = _accessorName(node.target);
    if (accessor == null) {
      return;
    }

    final typeName = _domainTypeName(node.typeArguments);
    if (typeName == null) {
      return;
    }

    final layer = _findLayer(context.currentUnit?.file.path, context);
    if (layer == 'domain') {
      return;
    }

    context.debug(
      'prefer_domain_di_factory: report $typeName at '
      '${node.offset}:${node.length}',
    );
    rule.reportAtNode(
      node.methodName,
      arguments: [typeName, accessor, _labelForAccessor(accessor)],
    );
  }
}

String? _accessorName(Expression? target) {
  if (target is SimpleIdentifier) {
    final name = target.name;
    if (name == 'Service' || name == 'Datasource') {
      return name;
    }
  }
  if (target is PrefixedIdentifier) {
    final name = target.identifier.name;
    if (name == 'Service' || name == 'Datasource') {
      return name;
    }
  }
  return null;
}

String? _domainTypeName(TypeArgumentList? typeArguments) {
  if (typeArguments == null || typeArguments.arguments.isEmpty) {
    return null;
  }
  final first = typeArguments.arguments.first;
  if (first is! NamedType) {
    return null;
  }
  final element = first.element;
  if (element == null) {
    return null;
  }
  if (!_isDomainContract(element)) {
    return null;
  }
  return first.name.lexeme;
}

bool _isDomainContract(Element element) {
  final fragment = element.firstFragment;
  final libraryFragment = fragment.libraryFragment;
  if (libraryFragment == null) {
    return false;
  }
  final sourcePath = libraryFragment.source.fullName.replaceAll('\\', '/');
  return sourcePath.contains('/domain/services/') ||
      sourcePath.contains('/domain/datasources/');
}

String _labelForAccessor(String accessor) {
  return accessor == 'Datasource' ? 'datasource' : 'service';
}

bool _isTestFile(RuleContext context, String? path) {
  if (path == null) {
    return false;
  }
  if (context.isInTestDirectory) {
    return true;
  }
  if (path.endsWith('_test.dart')) {
    return true;
  }
  final provider = context.currentUnit?.file.provider;
  final pathContext = provider?.pathContext;
  final packageRoot = context.package?.root.path;
  if (pathContext != null && packageRoot != null) {
    final relative = pathContext.relative(path, from: packageRoot);
    final segments = pathContext.split(relative);
    return segments.isNotEmpty && segments.first == 'test';
  }
  return false;
}

String? _findLayer(String? path, RuleContext context) {
  if (path == null) {
    return null;
  }
  final provider = context.currentUnit?.file.provider;
  final pathContext = provider?.pathContext;
  final packageRoot = context.package?.root.path;
  final relative = pathContext != null && packageRoot != null
      ? pathContext.relative(path, from: packageRoot)
      : path;
  final segments = pathContext != null
      ? pathContext.split(relative)
      : relative.split('/');
  for (final segment in segments) {
    if (segment == 'domain') {
      return 'domain';
    }
    if (segment == 'infra' || segment == 'infrastructure') {
      return 'infra';
    }
    if (segment == 'presentation') {
      return 'presentation';
    }
  }
  return null;
}
