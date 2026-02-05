// ignore: implementation_imports
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:grumpy_lints/src/fixes/domain_factory_from_di_fixes.dart';
import 'package:grumpy_lints/src/log.dart';
import 'package:grumpy_lints/src/rule.dart';

class DomainFactoryFromDiRule extends GrumpyRule {
  DomainFactoryFromDiRule()
    : super(
        name: 'domain_factory_from_di',
        description:
            'Requires domain services and datasources (excluding base classes) '
            'to declare an unnamed factory constructor that retrieves the '
            'implementation from DI.',
      );

  static const LintCode code = LintCode(
    'domain_factory_from_di_missing_factory',
    'Domain {0} must declare a DI factory constructor.',
    correctionMessage: 'Add a factory constructor that resolves from DI.',
    severity: DiagnosticSeverity.INFO,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  List<Example> get examples => [
    '// BAD: missing factory constructor\n'
            'abstract class RoutingService<T, Config> extends Service {}\n'
        .bad(),
    '// GOOD: factory constructor resolves from DI\n'
            'abstract class RoutingService<T, Config> extends Service {\n'
            '  /// Returns the DI-registered implementation of [RoutingService].\n///\n/// Shorthand for [Service.get]\n'
            '  factory RoutingService() {\n'
            '    return Service.get<RoutingService<T, Config>>();\n'
            '  }\n'
            '}\n'
        .good(),
  ];

  @override
  Map<DiagnosticCode, ProducerGenerator> get fixes => {
    code: AddDomainFactoryFromDiFix.new,
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
  final DomainFactoryFromDiRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) {
      return;
    }

    final unit = context.currentUnit;
    if (unit == null) {
      return;
    }
    final path = unit.file.path;
    if (_isTestFile(context, path)) {
      return;
    }

    final domainType = _domainTypeFromPath(path, context);
    if (domainType == null) {
      return;
    }

    if (_isBaseClass(element.displayName, domainType.kind)) {
      return;
    }

    if (_hasUnnamedFactory(node)) {
      return;
    }

    context.debug(
      'domain_factory_from_di: report ${element.displayName} at '
      '${node.offset}:${node.length}',
    );
    rule.reportAtNode(node.namePart, arguments: [domainType.label]);
  }
}

bool _hasUnnamedFactory(ClassDeclaration node) {
  final body = node.body;
  if (body is! BlockClassBody) {
    return false;
  }
  for (final member in body.members) {
    if (member is ConstructorDeclaration && member.factoryKeyword != null) {
      if (member.name == null) {
        return true;
      }
    }
  }
  return false;
}

bool _isBaseClass(String className, _DomainKind kind) {
  if (kind == _DomainKind.service) {
    return className == 'Service';
  }
  if (kind == _DomainKind.datasource) {
    return className == 'Datasource';
  }
  return false;
}

enum _DomainKind { service, datasource }

class _DomainTypeInfo {
  final _DomainKind kind;

  const _DomainTypeInfo(this.kind);

  String get label => kind == _DomainKind.service ? 'service' : 'datasource';

  factory _DomainTypeInfo.fromPath(String path, RuleContext context) {
    final provider = context.currentUnit?.file.provider;
    final pathContext = provider?.pathContext;
    final packageRoot = context.package?.root.path;
    final relative = pathContext != null && packageRoot != null
        ? pathContext.relative(path, from: packageRoot)
        : path;
    final segments = pathContext != null
        ? pathContext.split(relative)
        : relative.split('/');

    for (var i = 0; i < segments.length - 1; i++) {
      if (segments[i] != 'domain') {
        continue;
      }
      final next = segments[i + 1];
      if (next == 'services') {
        return const _DomainTypeInfo(_DomainKind.service);
      }
      if (next == 'datasources') {
        return const _DomainTypeInfo(_DomainKind.datasource);
      }
    }

    throw _DomainTypeInfoNotFound();
  }
}

class _DomainTypeInfoNotFound implements Exception {}

bool _isTestFile(RuleContext context, String path) {
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

_DomainTypeInfo? _domainTypeFromPath(String path, RuleContext context) {
  try {
    return _DomainTypeInfo.fromPath(path, context);
  } on _DomainTypeInfoNotFound {
    return null;
  }
}
