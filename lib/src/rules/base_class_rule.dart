// ignore: implementation_imports
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:grumpy_lints/src/log.dart';
import 'package:grumpy_lints/src/rule.dart';

class BaseClassRule extends GrumpyRule {
  BaseClassRule()
    : super(
        name: 'base_class',
        description:
            'Enforces the BaseClass contract: subclasses must live in allowed '
            'layers, use the base class name as a suffix when forceSuffix is '
            'true, reside in the configured type directory with a snake_case '
            'filename, be the only class in the file, and any class inside the '
            'type directory must extend the base class. Test files are exempt.',
      );

  static const LintCode invalidLayerCode = LintCode(
    'base_class_invalid_layer',
    'Classes extending {0} must be defined in layers: {1}.',
    correctionMessage: 'Move the class to one of the allowed layers: {1}.',
    severity: DiagnosticSeverity.INFO,
  );

  static const LintCode missingSuffixCode = LintCode(
    'base_class_missing_suffix',
    'Class {0} must end with {1}.',
    correctionMessage:
        'Rename the class to end with `{1}` or disable forceSuffix on the '
        'base class.',
    severity: DiagnosticSeverity.INFO,
  );

  static const LintCode wrongDirectoryCode = LintCode(
    'base_class_wrong_directory',
    'Class {0} must be inside the {1} directory.',
    correctionMessage: 'Move the file into the `{1}` directory.',
    severity: DiagnosticSeverity.INFO,
  );

  static const LintCode wrongFileNameCode = LintCode(
    'base_class_wrong_file_name',
    'File name for {0} must be {1}.',
    correctionMessage: 'Rename the file to `{1}`.',
    severity: DiagnosticSeverity.INFO,
  );

  static const LintCode extraClassCode = LintCode(
    'base_class_extra_class',
    'File declaring {0} must not declare any other classes.',
    correctionMessage: 'Move other classes to their own files.',
    severity: DiagnosticSeverity.INFO,
  );

  static const LintCode missingExtensionCode = LintCode(
    'base_class_missing_extension',
    'Classes in {0} must extend {1}.',
    correctionMessage: 'Make the class extend `{1}` or move it elsewhere.',
    severity: DiagnosticSeverity.INFO,
  );

  @override
  DiagnosticCode get diagnosticCode => invalidLayerCode;

  @override
  List<DiagnosticCode> get diagnosticCodes => [
    invalidLayerCode,
    missingSuffixCode,
    wrongDirectoryCode,
    wrongFileNameCode,
    extraClassCode,
    missingExtensionCode,
  ];

  @override
  List<Example> get examples => [
    '// Base class:\n'
            '@BaseClass(allowedLayers: {LayerType.domain}, '
            "typeDirectory: 'services')\n"
            'abstract class Service {}\n\n'
            '// File: lib/src/module/domain/services/user_service.dart\n'
            'abstract class UserService extends Service {}\n'
        .good(),
    '// Wrong layer (presentation is not allowed).\n'
            '// File: lib/src/module/presentation/services/user_service.dart\n'
            'abstract class UserService extends Service {}\n'
        .bad(),
    '// Missing suffix when forceSuffix is true.\n'
            '// File: lib/src/module/domain/services/user_manager.dart\n'
            'abstract class UserManager extends Service {}\n'
        .bad(),
    '// Wrong directory (should be services/).\n'
            '// File: lib/src/module/domain/user_service.dart\n'
            'abstract class UserService extends Service {}\n'
        .bad(),
    '// Wrong file name (should be user_service.dart).\n'
            '// File: lib/src/module/domain/services/userService.dart\n'
            'abstract class UserService extends Service {}\n'
        .bad(),
    '// Extra class in the same file.\n'
            '// File: lib/src/module/domain/services/user_service.dart\n'
            'abstract class UserService extends Service {}\n\n'
            'class Helper {}\n'
        .bad(),
    '// Class in the services/ directory must extend Service.\n'
            '// File: lib/src/module/domain/services/user_service.dart\n'
            'abstract class UserService {}\n'
        .bad(),
  ];

  @override
  Map<DiagnosticCode, ProducerGenerator> get fixes => const {};

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final BaseClassRule rule;
  final RuleContext context;
  final List<_BaseClassInfo> baseClasses;
  late final Map<String, List<_BaseClassInfo>> baseClassesByDirectory;

  _Visitor(this.rule, this.context)
    : baseClasses = _collectBaseClasses(context) {
    baseClassesByDirectory = _indexByDirectory(baseClasses);
  }

  void _reportWithCode(
    AstNode node,
    DiagnosticCode code,
    List<Object> arguments,
  ) {
    context.debug(
      'base_class: report ${code.lowerCaseName} at ${node.offset}:${node.length}',
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
    final unit = context.currentUnit;
    if (unit == null) {
      return;
    }
    final path = unit.file.path;
    if (_isTestFile(context, path)) {
      return;
    }

    if (_findBaseClassAnnotation(element) != null) {
      return;
    }

    final baseInfo = _findBaseClassInfo(element);
    final pathInfo = _PathInfo.fromPath(path, context);

    if (baseInfo != null) {
      _checkSubclassRules(node, element, baseInfo, pathInfo, unit.unit);
      return;
    }

    _checkDirectoryRules(node, element, pathInfo);
  }

  void _checkSubclassRules(
    ClassDeclaration node,
    ClassElement element,
    _BaseClassInfo baseInfo,
    _PathInfo pathInfo,
    CompilationUnit unit,
  ) {
    final className = element.displayName;
    if (pathInfo.layer == null ||
        !baseInfo.allowedLayers.contains(pathInfo.layer)) {
      _reportWithCode(node.namePart, BaseClassRule.invalidLayerCode, [
        className,
        baseInfo.allowedLayersLabel,
      ]);
    }

    if (baseInfo.forceSuffix && !className.endsWith(baseInfo.name)) {
      _reportWithCode(node.namePart, BaseClassRule.missingSuffixCode, [
        className,
        baseInfo.name,
      ]);
    }

    if (!pathInfo.isInTypeDirectory(baseInfo.typeDirectory)) {
      _reportWithCode(node.namePart, BaseClassRule.wrongDirectoryCode, [
        className,
        baseInfo.typeDirectory,
      ]);
    }

    final expectedFileName = '${_toSnakeCase(className)}.dart';
    if (pathInfo.fileName != expectedFileName) {
      _reportWithCode(node.namePart, BaseClassRule.wrongFileNameCode, [
        className,
        expectedFileName,
      ]);
    }

    final classDeclarations = unit.declarations
        .whereType<ClassDeclaration>()
        .toList();
    if (classDeclarations.length > 1) {
      _reportWithCode(node.namePart, BaseClassRule.extraClassCode, [className]);
    }
  }

  void _checkDirectoryRules(
    ClassDeclaration node,
    ClassElement element,
    _PathInfo pathInfo,
  ) {
    final layer = pathInfo.layer;
    if (layer == null || pathInfo.typeDirectory == null) {
      return;
    }
    final candidates = baseClassesByDirectory[pathInfo.typeDirectory];
    if (candidates == null || candidates.isEmpty) {
      return;
    }

    for (final baseInfo in candidates) {
      if (!baseInfo.allowedLayers.contains(layer)) {
        continue;
      }
      if (element == baseInfo.element) {
        continue;
      }
      _reportWithCode(node.namePart, BaseClassRule.missingExtensionCode, [
        baseInfo.typeDirectory,
        baseInfo.name,
      ]);
      return;
    }
  }

  _BaseClassInfo? _findBaseClassInfo(ClassElement element) {
    for (final supertype in element.allSupertypes) {
      final superElement = supertype.element;
      if (superElement is! ClassElement) {
        continue;
      }
      final annotation = _findBaseClassAnnotation(superElement);
      if (annotation == null) {
        continue;
      }
      return _BaseClassInfo.fromAnnotation(annotation, superElement);
    }
    return null;
  }
}

class _BaseClassInfo {
  final ClassElement element;
  final String name;
  final Set<String> allowedLayers;
  final String allowedLayersLabel;
  final String typeDirectory;
  final bool forceSuffix;

  const _BaseClassInfo({
    required this.element,
    required this.name,
    required this.allowedLayers,
    required this.allowedLayersLabel,
    required this.typeDirectory,
    required this.forceSuffix,
  });

  factory _BaseClassInfo.fromAnnotation(
    ElementAnnotation annotation,
    ClassElement element,
  ) {
    final value = annotation.computeConstantValue();
    final typeDirectoryValue = value
        ?.getField('typeDirectory')
        ?.toStringValue();
    final forceSuffixValue = value?.getField('forceSuffix')?.toBoolValue();
    final allowedLayers = _readAllowedLayers(value);
    final typeDirectory = typeDirectoryValue?.isNotEmpty == true
        ? typeDirectoryValue!
        : _pluralize(_toSnakeCase(element.displayName));
    final allowedLayersLabel = _sortedLabel(allowedLayers);
    final forceSuffix = forceSuffixValue ?? true;

    return _BaseClassInfo(
      element: element,
      name: element.displayName,
      allowedLayers: allowedLayers,
      allowedLayersLabel: allowedLayersLabel,
      typeDirectory: typeDirectory,
      forceSuffix: forceSuffix,
    );
  }
}

class _PathInfo {
  final String fileName;
  final String? layer;
  final String? typeDirectory;

  _PathInfo({
    required this.fileName,
    required this.layer,
    required this.typeDirectory,
  });

  factory _PathInfo.fromPath(String path, RuleContext context) {
    final provider = context.currentUnit?.file.provider;
    final pathContext = provider?.pathContext;
    final fileName = pathContext?.basename(path) ?? path.split('/').last;
    final packageRoot = context.package?.root.path;
    final relative = pathContext != null && packageRoot != null
        ? pathContext.relative(path, from: packageRoot)
        : path;
    final segments = pathContext != null
        ? pathContext.split(relative)
        : relative.split('/');

    var layer = _findLayer(segments);
    var layerIndex = layer?.index;
    String? typeDirectory;
    if (layerIndex != null && layerIndex + 1 < segments.length) {
      typeDirectory = segments[layerIndex + 1];
    }

    return _PathInfo(
      fileName: fileName,
      layer: layer?.name,
      typeDirectory: typeDirectory,
    );
  }

  bool isInTypeDirectory(String expected) => typeDirectory == expected;
}

class _LayerInfo {
  final String name;
  final int index;

  const _LayerInfo(this.name, this.index);
}

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

_LayerInfo? _findLayer(List<String> segments) {
  for (var i = 0; i < segments.length; i++) {
    final segment = segments[i];
    if (segment == 'domain') {
      return _LayerInfo('domain', i);
    }
    if (segment == 'infra' || segment == 'infrastructure') {
      return _LayerInfo('infra', i);
    }
    if (segment == 'presentation') {
      return _LayerInfo('presentation', i);
    }
  }
  return null;
}

List<_BaseClassInfo> _collectBaseClasses(RuleContext context) {
  final library = context.libraryElement;
  if (library == null) {
    return const [];
  }
  final packageRoot = context.package?.root.path;
  final visited = <LibraryElement>{};
  final result = <_BaseClassInfo>[];

  void visit(LibraryElement current) {
    if (!visited.add(current)) {
      return;
    }
    final fragment = current.firstFragment;
    if (packageRoot != null) {
      final sourcePath = fragment.source.fullName;
      if (!sourcePath.startsWith(packageRoot)) {
        return;
      }
    }
    for (final element in current.classes) {
      final annotation = _findBaseClassAnnotation(element);
      if (annotation == null) {
        continue;
      }
      result.add(_BaseClassInfo.fromAnnotation(annotation, element));
    }
    for (final imported in fragment.importedLibraries) {
      visit(imported);
    }
    for (final exported in fragment.libraryExports) {
      final exportedLibrary = exported.exportedLibrary;
      if (exportedLibrary != null) {
        visit(exportedLibrary);
      }
    }
  }

  visit(library);
  return result;
}

Map<String, List<_BaseClassInfo>> _indexByDirectory(
  List<_BaseClassInfo> baseClasses,
) {
  final result = <String, List<_BaseClassInfo>>{};
  for (final baseClass in baseClasses) {
    result.putIfAbsent(baseClass.typeDirectory, () => []).add(baseClass);
  }
  return result;
}

ElementAnnotation? _findBaseClassAnnotation(InterfaceElement element) {
  for (final annotation in element.metadata.annotations) {
    if (_isBaseClassAnnotation(annotation)) {
      return annotation;
    }
  }
  return null;
}

bool _isBaseClassAnnotation(ElementAnnotation annotation) {
  final element = annotation.element;
  if (element == null) {
    return false;
  }
  final name = element.displayName;
  if (name == 'BaseClass' || name == 'base') {
    return true;
  }
  final enclosingName = element.enclosingElement?.displayName;
  return enclosingName == 'BaseClass';
}

Set<String> _readAllowedLayers(DartObject? value) {
  final allowed = value?.getField('allowedLayers')?.toSetValue();
  if (allowed == null || allowed.isEmpty) {
    return {'domain', 'infra', 'presentation'};
  }
  final result = <String>{};
  const fallbackNames = ['infra', 'domain', 'presentation'];
  for (final entry in allowed) {
    final name = entry.getField('name')?.toStringValue();
    if (name != null && name.isNotEmpty) {
      result.add(name);
      continue;
    }
    final index = entry.getField('index')?.toIntValue();
    if (index != null && index >= 0 && index < fallbackNames.length) {
      result.add(fallbackNames[index]);
      continue;
    }
    if (name == null || name.isEmpty) {
      continue;
    }
  }
  if (result.isEmpty) {
    return {'domain', 'infra', 'presentation'};
  }
  return result;
}

String _toSnakeCase(String name) {
  final buffer = StringBuffer();
  for (var i = 0; i < name.length; i++) {
    final char = name[i];
    final isUpper = char.toUpperCase() == char && char.toLowerCase() != char;
    if (isUpper && i > 0) {
      buffer.write('_');
    }
    buffer.write(char.toLowerCase());
  }
  return buffer.toString();
}

String _pluralize(String value) {
  if (value.endsWith('s')) {
    return value;
  }
  if (value.endsWith('y') && value.length > 1) {
    final before = value[value.length - 2];
    final isVowel = 'aeiou'.contains(before);
    if (!isVowel) {
      return '${value.substring(0, value.length - 1)}ies';
    }
  }
  return '${value}s';
}

String _sortedLabel(Set<String> values) {
  final list = values.toList()..sort();
  return list.join(', ');
}
