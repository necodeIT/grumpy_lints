import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddDomainFactoryFromDiFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'grumpy.fix.addDomainFactoryFromDi',
    DartFixKindPriority.standard,
    'Add DI factory constructor',
  );

  AddDomainFactoryFromDiFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final classDecl = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classDecl == null) {
      return;
    }

    final body = classDecl.body;
    if (body is! BlockClassBody) {
      return;
    }

    final namePart = classDecl.namePart;
    final className = namePart.typeName.lexeme;
    final typeArgs = _typeArgumentList(namePart.typeParameters);
    final classType = '$className$typeArgs';
    final accessor = _accessorFromPath(file);
    final needsPrivateConstructor = !_hasGenerativeConstructor(body);

    final eol = utils.endOfLine;
    final classIndent = utils.getLinePrefix(body.rightBracket.offset);
    final memberIndent = classIndent + utils.oneIndent;
    final bodyBetween = utils.getText(
      body.leftBracket.end,
      body.rightBracket.offset - body.leftBracket.end,
    );
    final leadingEol = bodyBetween.contains('\n') || bodyBetween.contains('\r')
        ? ''
        : eol;

    final source = StringBuffer()
      ..write(leadingEol)
      ..write(
        _privateConstructorSource(
          needsPrivateConstructor,
          className,
          memberIndent,
          eol,
        ),
      )
      ..write(
        '$memberIndent/// Returns the DI-registered implementation of [$className].',
      )
      ..write(eol)
      ..write('$memberIndent///')
      ..write(eol)
      ..write('$memberIndent/// Shorthand for [$accessor.get].')
      ..write(eol)
      ..write(
        '$memberIndent'
        'factory $className() {$eol',
      )
      ..write(
        '$memberIndent${utils.oneIndent}return $accessor.get<$classType>();$eol',
      )
      ..write('$memberIndent}$eol');

    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(body.rightBracket.offset, (builder) {
        builder.write(source.toString());
      });
    });
  }

  String _typeArgumentList(TypeParameterList? typeParameters) {
    if (typeParameters == null || typeParameters.typeParameters.isEmpty) {
      return '';
    }
    final names = typeParameters.typeParameters
        .map((parameter) => parameter.name.lexeme)
        .join(', ');
    return '<$names>';
  }

  String _accessorFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    if (normalized.contains('/domain/datasources/')) {
      return 'Datasource';
    }
    return 'Service';
  }

  String _privateConstructorSource(
    bool shouldAdd,
    String className,
    String indent,
    String eol,
  ) {
    if (!shouldAdd) {
      return '';
    }
    return '$indent/// Internal constructor for subclasses.\n$indent$className.internal();$eol';
  }

  bool _hasGenerativeConstructor(BlockClassBody body) {
    for (final member in body.members) {
      if (member is ConstructorDeclaration) {
        if (member.factoryKeyword == null) {
          return true;
        }
      }
    }
    return false;
  }
}
