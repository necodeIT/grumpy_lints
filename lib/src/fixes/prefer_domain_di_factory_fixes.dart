import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class PreferDomainDiFactoryFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'grumpy.fix.preferDomainDiFactory',
    DartFixKindPriority.standard,
    'Use domain DI factory constructor',
  );

  PreferDomainDiFactoryFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final invocation = node.thisOrAncestorOfType<MethodInvocation>();
    if (invocation == null) {
      return;
    }

    final typeName = _typeNameFrom(invocation.typeArguments);
    if (typeName == null) {
      return;
    }

    final replacement = '$typeName()';

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(invocation), (builder) {
        builder.write(replacement);
      });
    });
  }

  String? _typeNameFrom(TypeArgumentList? typeArguments) {
    if (typeArguments == null || typeArguments.arguments.isEmpty) {
      return null;
    }
    final first = typeArguments.arguments.first;
    if (first is! NamedType) {
      return null;
    }

    final prefix = first.importPrefix?.name.lexeme;
    final name = first.name.lexeme;
    final typeArgs = first.typeArguments;
    final typeArgText = typeArgs == null
        ? ''
        : utils.getText(typeArgs.offset, typeArgs.length);

    final buffer = StringBuffer();
    if (prefix != null && prefix.isNotEmpty) {
      buffer.write(prefix);
      buffer.write('.');
    }
    buffer.write(name);
    buffer.write(typeArgText);
    return buffer.toString();
  }
}
