// ignore: implementation_imports
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:grumpy_lints/src/fixes/must_call_in_constructor_fixes.dart';
import 'package:grumpy_lints/src/log.dart';
import 'package:grumpy_lints/src/rule.dart';

class MustCallInConstructorRule extends GrumpyRule {
  MustCallInConstructorRule()
    : super(
        name: 'must_call_in_constructor',
        description:
            'Requires constructors to call methods annotated with '
            '@mustCallInConstructor from supertypes or mixins. It respects '
            'concreteOnly (abstract classes must not call those methods) and '
            'exempt (subtypes listed as exempt must not call the method at '
            'all).',
      );

  static const LintCode code = LintCode(
    'missing_required_constructor_call',
    'Call {0} in the constructor, as required by {1}.',
    correctionMessage: 'Add the required `{0}` call to the constructor.',

    severity: DiagnosticSeverity.ERROR,
  );

  static const LintCode initializerCode = LintCode(
    'missing_required_initializer_call',
    'Call {0} in the initializer, as required by {1}.',
    correctionMessage: 'Add the required `{0}` call to the initializer.',
    severity: DiagnosticSeverity.ERROR,
  );

  static const LintCode abstractCode = LintCode(
    'avoid_abstract_constructor_calls',
    'Do not call {0} in an abstract constructor. '
        'Required by {1} for concrete classes.',
    correctionMessage: 'Remove the `{0}` call from the constructor.',
    severity: DiagnosticSeverity.ERROR,
  );

  static const LintCode abstractInitializerCode = LintCode(
    'avoid_abstract_initializer_calls',
    'Do not call {0} in an abstract initializer. '
        'Required by {1} for concrete classes.',
    correctionMessage: 'Remove the `{0}` call from the initializer.',
    severity: DiagnosticSeverity.ERROR,
  );

  static const LintCode exemptCode = LintCode(
    'avoid_exempt_constructor_calls',
    'Do not call {0} in the constructor. Exempt for {1}.',
    correctionMessage: 'Remove the `{0}` call from the constructor.',
    severity: DiagnosticSeverity.INFO,
  );

  static const LintCode exemptInitializerCode = LintCode(
    'avoid_exempt_initializer_calls',
    'Do not call {0} in the initializer. Exempt for {1}.',
    correctionMessage: 'Remove the `{0}` call from the initializer.',
    severity: DiagnosticSeverity.INFO,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  List<DiagnosticCode> get diagnosticCodes => [
    code,
    initializerCode,
    abstractCode,
    abstractInitializerCode,
    exemptCode,
    exemptInitializerCode,
  ];

  @override
  List<Example> get examples => [
    '// Missing required call in the constructor.\n'
            'mixin InitMixin {\n'
            '  @mustCallInConstructor\n'
            '  void init() {}\n'
            '}\n\n'
            'class Widget with InitMixin {\n'
            '  Widget();\n'
            '}\n'
        .bad(),
    '// Required call is present.\n'
            'mixin InitMixin {\n'
            '  @mustCallInConstructor\n'
            '  void init() {}\n'
            '}\n\n'
            'class Widget with InitMixin {\n'
            '  Widget() {\n'
            '    init();\n'
            '  }\n'
            '}\n'
        .good(),
    '// Abstract classes must not call methods that are concreteOnly.\n'
            'mixin InitMixin {\n'
            '  @MustCallInConstructor(concreteOnly: true)\n'
            '  void init() {}\n'
            '}\n\n'
            'abstract class BaseWidget with InitMixin {\n'
            '  BaseWidget() {\n'
            '    init();\n'
            '  }\n'
            '}\n'
        .bad(),
    '// Exempt types must not call the annotated method.\n'
            'mixin InitMixin {\n'
            '  @MustCallInConstructor(exempt: [NoopWidget])\n'
            '  void init() {}\n'
            '}\n\n'
            'class NoopWidget with InitMixin {\n'
            '  NoopWidget() {\n'
            '    init();\n'
            '  }\n'
            '}\n'
        .bad(),
    '// Exempt types can omit the call entirely.\n'
            'mixin InitMixin {\n'
            '  @MustCallInConstructor(exempt: [NoopWidget])\n'
            '  void init() {}\n'
            '}\n\n'
            'class NoopWidget with InitMixin {\n'
            '  NoopWidget();\n'
            '}\n'
        .good(),
  ];

  @override
  Map<DiagnosticCode, ProducerGenerator> get fixes => {
    code: AddRequiredConstructorCallFix.new,
    initializerCode: AddRequiredInitializerCallFix.new,
    abstractCode: RemoveAbstractConstructorCallFix.new,
    abstractInitializerCode: RemoveAbstractInitializerCallFix.new,
    exemptCode: RemoveAbstractConstructorCallFix.new,
    exemptInitializerCode: RemoveAbstractInitializerCallFix.new,
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
  final MustCallInConstructorRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  void _reportWithCode(
    AstNode node,
    DiagnosticCode code,
    List<Object> arguments,
  ) {
    context.debug(
      'must_call_in_constructor: report ${code.lowerCaseName} at '
      '${node.offset}:${node.length}',
    );
    final reporter = context.currentUnit?.diagnosticReporter;
    if (reporter == null) {
      return;
    }
    reporter.atNode(node, code, arguments: arguments);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null) {
      return;
    }

    context.debug('must_call_in_constructor: checking ${element.displayName}');

    final requiredByName = _collectRequiredMethods(element);
    if (requiredByName.isEmpty) {
      return;
    }

    final requiredMethods = <_RequiredMethod>[];
    final concreteOnlyMethods = <_RequiredMethod>[];
    final exemptMethods = <_RequiredMethod>[];
    for (final entry in requiredByName.values) {
      if (entry.isExemptFor(element)) {
        exemptMethods.add(entry);
        continue;
      }
      if (entry.hasConcreteOnlyOwners) {
        concreteOnlyMethods.add(entry);
      }
      if (element.isAbstract && !entry.appliesToAbstract) {
        continue;
      }
      requiredMethods.add(entry);
    }
    if (requiredMethods.isEmpty &&
        concreteOnlyMethods.isEmpty &&
        exemptMethods.isEmpty) {
      return;
    }

    final body = node.body;
    final constructors = body is BlockClassBody
        ? body.members.whereType<ConstructorDeclaration>().toList()
        : const <ConstructorDeclaration>[];
    final initializers = _collectInitializerMethods(body);
    if (initializers.isNotEmpty) {
      final initializerInvocations = [
        for (final initializer in initializers)
          _InitializerInvocation(
            initializer,
            _collectInvokedMethods(initializer.body),
          ),
      ];
      final invoked = {
        for (final invocation in initializerInvocations) ...invocation.invoked,
      };

      final reportNode = initializers.first;
      for (final required in requiredMethods) {
        if (invoked.contains(required.name)) {
          continue;
        }
        context.debug(
          'must_call_in_constructor: missing ${required.name} in '
          '${element.displayName} initializer',
        );
        _reportWithCode(reportNode, MustCallInConstructorRule.initializerCode, [
          required.name,
          required.ownersLabelForRequirement(isAbstract: element.isAbstract),
        ]);
      }

      if (exemptMethods.isNotEmpty) {
        for (final invocation in initializerInvocations) {
          for (final required in exemptMethods) {
            if (!invocation.invoked.contains(required.name)) {
              continue;
            }
            _reportWithCode(
              invocation.method,
              MustCallInConstructorRule.exemptInitializerCode,
              [required.name, required.exemptTypeLabel],
            );
          }
        }
      }

      if (element.isAbstract && concreteOnlyMethods.isNotEmpty) {
        for (final invocation in initializerInvocations) {
          for (final required in concreteOnlyMethods) {
            if (!invocation.invoked.contains(required.name)) {
              continue;
            }
            _reportWithCode(
              invocation.method,
              MustCallInConstructorRule.abstractInitializerCode,
              [required.name, required.concreteOnlyOwnersLabel],
            );
          }
        }
      }

      if (constructors.isNotEmpty) {
        for (final constructor in constructors) {
          if (constructor.redirectedConstructor != null) {
            continue;
          }
          final invoked = _collectInvokedMethods(constructor.body);
          if (exemptMethods.isNotEmpty) {
            for (final required in exemptMethods) {
              if (!invoked.contains(required.name)) {
                continue;
              }
              _reportWithCode(
                constructor,
                MustCallInConstructorRule.exemptCode,
                [required.name, required.exemptTypeLabel],
              );
            }
          }
          if (element.isAbstract && concreteOnlyMethods.isNotEmpty) {
            for (final required in concreteOnlyMethods) {
              if (!invoked.contains(required.name)) {
                continue;
              }
              _reportWithCode(
                constructor,
                MustCallInConstructorRule.abstractCode,
                [required.name, required.concreteOnlyOwnersLabel],
              );
            }
          }
        }
      }

      return;
    }

    if (constructors.isEmpty) {
      for (final required in requiredMethods) {
        context.debug(
          'must_call_in_constructor: missing ${required.name} in '
          '${element.displayName}',
        );
        rule.reportAtNode(
          node.namePart,
          arguments: [
            required.name,
            required.ownersLabelForRequirement(isAbstract: element.isAbstract),
          ],
        );
      }
      return;
    }

    for (final constructor in constructors) {
      if (constructor.redirectedConstructor != null) {
        continue;
      }
      final invoked = _collectInvokedMethods(constructor.body);
      for (final required in requiredMethods) {
        if (invoked.contains(required.name)) {
          continue;
        }
        context.debug(
          'must_call_in_constructor: missing ${required.name} in '
          '${element.displayName} constructor',
        );
        rule.reportAtNode(
          constructor,
          arguments: [
            required.name,
            required.ownersLabelForRequirement(isAbstract: element.isAbstract),
          ],
        );
      }

      if (exemptMethods.isNotEmpty) {
        for (final required in exemptMethods) {
          if (!invoked.contains(required.name)) {
            continue;
          }
          _reportWithCode(constructor, MustCallInConstructorRule.exemptCode, [
            required.name,
            required.exemptTypeLabel,
          ]);
        }
      }

      if (element.isAbstract && concreteOnlyMethods.isNotEmpty) {
        for (final required in concreteOnlyMethods) {
          if (!invoked.contains(required.name)) {
            continue;
          }
          _reportWithCode(constructor, MustCallInConstructorRule.abstractCode, [
            required.name,
            required.concreteOnlyOwnersLabel,
          ]);
        }
      }
    }
  }
}

Map<String, _RequiredMethod> _collectRequiredMethods(ClassElement element) {
  final result = <String, _RequiredMethod>{};
  final visited = <InterfaceElement>{};

  void visitInterface(InterfaceElement interface) {
    if (!visited.add(interface)) {
      return;
    }

    for (final method in interface.methods) {
      if (method.isStatic) {
        continue;
      }
      final annotation = _findMustCallAnnotation(method);
      if (annotation == null) {
        continue;
      }

      final concreteOnly = _isConcreteOnly(annotation);
      final exemptTypes = _exemptTypes(annotation);
      final name = method.displayName;
      final owner = interface.displayName;
      final existing = result[name];
      if (existing == null) {
        result[name] = _RequiredMethod(name, concreteOnly, owner, exemptTypes);
      } else {
        existing.merge(
          concreteOnly: concreteOnly,
          owner: owner,
          exemptTypes: exemptTypes,
        );
      }
    }

    if (interface is ClassElement) {
      final supertype = interface.supertype;
      if (supertype != null && !interface.isDartCoreObject) {
        visitInterface(supertype.element);
      }
      for (final mixin in interface.mixins) {
        visitInterface(mixin.element);
      }
    }
  }

  final supertype = element.supertype;
  if (supertype != null && !element.isDartCoreObject) {
    visitInterface(supertype.element);
  }
  for (final mixin in element.mixins) {
    visitInterface(mixin.element);
  }

  return result;
}

ElementAnnotation? _findMustCallAnnotation(MethodElement method) {
  for (final annotation in method.metadata.annotations) {
    if (_isMustCallAnnotation(annotation)) {
      return annotation;
    }
  }
  return null;
}

ElementAnnotation? _findInitializerAnnotation(ExecutableElement method) {
  for (final annotation in method.metadata.annotations) {
    if (_isInitializerAnnotation(annotation)) {
      return annotation;
    }
  }
  return null;
}

bool _isMustCallAnnotation(ElementAnnotation annotation) {
  final element = annotation.element;
  if (element == null) {
    return false;
  }
  final name = element.displayName;
  if (name == 'mustCallInConstructor' || name == 'MustCallInConstructor') {
    return true;
  }
  final enclosingName = element.enclosingElement?.displayName;
  if (enclosingName == 'MustCallInConstructor') {
    return true;
  }
  return false;
}

bool _isInitializerAnnotation(ElementAnnotation annotation) {
  final element = annotation.element;
  if (element == null) {
    return false;
  }
  final name = element.displayName;
  if (name == 'initializer' || name == 'Initializer') {
    return true;
  }
  final enclosingName = element.enclosingElement?.displayName;
  if (enclosingName == 'Initializer') {
    return true;
  }
  return false;
}

bool _isConcreteOnly(ElementAnnotation annotation) {
  final value = annotation.computeConstantValue();
  final concreteOnly = value?.getField('concreteOnly')?.toBoolValue();
  return concreteOnly ?? true;
}

List<DartType> _exemptTypes(ElementAnnotation annotation) {
  final value = annotation.computeConstantValue();
  final listValue = value?.getField('exempt')?.toListValue();
  if (listValue == null || listValue.isEmpty) {
    return const [];
  }
  final types = <DartType>[];
  for (final entry in listValue) {
    final typeValue = entry.toTypeValue();
    if (typeValue != null) {
      types.add(typeValue);
    }
  }
  return types;
}

Set<String> _collectInvokedMethods(FunctionBody body) {
  final visitor = _InvokedMethodVisitor();
  body.accept(visitor);
  return visitor.invoked;
}

List<MethodDeclaration> _collectInitializerMethods(ClassBody body) {
  if (body is! BlockClassBody) {
    return const [];
  }
  final initializers = <MethodDeclaration>[];
  for (final member in body.members) {
    if (member is! MethodDeclaration) {
      continue;
    }

    final element = member.declaredFragment?.element;
    if (element == null) {
      continue;
    }
    if (_findInitializerAnnotation(element) != null) {
      initializers.add(member);
    }
  }
  return initializers;
}

class _RequiredMethod {
  final String name;
  final Set<String> concreteOnlyOwners = {};
  final Set<String> anyOwners = {};
  final List<DartType> exemptTypes = [];
  final Set<String> exemptTypeLabels = {};

  _RequiredMethod(
    this.name,
    bool concreteOnly,
    String owner,
    Iterable<DartType> exemptTypes,
  ) {
    merge(concreteOnly: concreteOnly, owner: owner, exemptTypes: exemptTypes);
  }

  void merge({
    required bool concreteOnly,
    required String owner,
    Iterable<DartType> exemptTypes = const [],
  }) {
    if (concreteOnly) {
      concreteOnlyOwners.add(owner);
    } else {
      anyOwners.add(owner);
    }
    _addExemptTypes(exemptTypes);
  }

  bool get appliesToAbstract => anyOwners.isNotEmpty;

  bool get hasConcreteOnlyOwners => concreteOnlyOwners.isNotEmpty;

  String get concreteOnlyOwnersLabel => _sortedLabel(concreteOnlyOwners);

  String get exemptTypeLabel => _sortedLabel(exemptTypeLabels);

  bool isExemptFor(ClassElement element) {
    if (exemptTypes.isEmpty) {
      return false;
    }
    final typeSystem = element.library.typeSystem;
    final selfType = element.thisType;
    for (final exemptType in exemptTypes) {
      if (typeSystem.isSubtypeOf(selfType, exemptType)) {
        return true;
      }
    }
    return false;
  }

  String ownersLabelForRequirement({required bool isAbstract}) {
    if (isAbstract && anyOwners.isNotEmpty) {
      return _sortedLabel(anyOwners);
    }
    final merged = <String>{...anyOwners, ...concreteOnlyOwners};
    return _sortedLabel(merged);
  }

  String _sortedLabel(Set<String> owners) {
    final list = owners.toList()..sort();
    return list.join(', ');
  }

  void _addExemptTypes(Iterable<DartType> types) {
    for (final exemptType in types) {
      final label = exemptType.getDisplayString();
      if (exemptTypeLabels.add(label)) {
        exemptTypes.add(exemptType);
      }
    }
  }
}

class _InvokedMethodVisitor extends RecursiveAstVisitor<void> {
  final Set<String> invoked = {};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final element = node.methodName.element;
    if (element is MethodElement &&
        element.enclosingElement is InterfaceElement) {
      invoked.add(element.displayName);
    }
    super.visitMethodInvocation(node);
  }
}

class _InitializerInvocation {
  final MethodDeclaration method;
  final Set<String> invoked;

  _InitializerInvocation(this.method, this.invoked);
}
