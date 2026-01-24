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
import 'package:grumpy_lints/src/rule.dart';

class MustCallInConstructorRule extends GrumpyRule {
  MustCallInConstructorRule()
    : super(
        name: 'must_call_in_constructor',
        description:
            'Require constructors to call methods annotated with '
            '@mustCallInConstructor on supertypes or mixins.',
      );

  static const LintCode code = LintCode(
    'missing_required_constructor_call',
    'Call {0} in the constructor, as required by {1}.',
    correctionMessage: 'Add the required `{0}` call to the constructor.',

    severity: DiagnosticSeverity.ERROR,
  );

  static const LintCode abstractCode = LintCode(
    'avoid_abstract_constructor_calls',
    'Do not call {0} in an abstract constructor. '
        'Required by {1} for concrete classes.',
    correctionMessage: 'Remove the `{0}` call from the constructor.',
    severity: DiagnosticSeverity.ERROR,
  );

  static const LintCode exemptCode = LintCode(
    'avoid_exempt_constructor_calls',
    'Do not call {0} in the constructor. Exempt for {1}.',
    correctionMessage: 'Remove the `{0}` call from the constructor.',
    severity: DiagnosticSeverity.ERROR,
  );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  List<DiagnosticCode> get diagnosticCodes => [code, abstractCode, exemptCode];

  @override
  Map<DiagnosticCode, ProducerGenerator> get fixes => {
    code: AddRequiredConstructorCallFix.new,
    abstractCode: RemoveAbstractConstructorCallFix.new,
    exemptCode: RemoveAbstractConstructorCallFix.new,
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
    if (constructors.isEmpty) {
      for (final required in requiredMethods) {
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
      final invoked = _collectInvokedMethods(constructor);
      for (final required in requiredMethods) {
        if (invoked.contains(required.name)) {
          continue;
        }
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

Set<String> _collectInvokedMethods(ConstructorDeclaration constructor) {
  final visitor = _ConstructorCallVisitor();
  constructor.body.accept(visitor);
  return visitor.invoked;
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

class _ConstructorCallVisitor extends RecursiveAstVisitor<void> {
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
