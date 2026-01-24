import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:grumpy_lints/src/rules/logging_utils.dart';

class SetLogTagFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'grumpy.fix.setLogTag',
    DartFixKindPriority.standard,
    'Set logTag to the class name',
  );

  SetLogTagFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final classDeclaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classDeclaration == null) {
      return;
    }
    final element = classDeclaration.declaredFragment?.element;
    if (element == null) {
      return;
    }

    final className = element.displayName;
    final expression = expectedLogTagExpression(className);

    final target = findMemberTarget(classDeclaration, 'logTag');
    if (target?.expression != null) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addReplacement(range.node(target!.expression!), (builder) {
          builder.write(expression);
        });
      });
      return;
    }

    if (target != null) {
      final indent = utils.getLinePrefix(target.member.offset);
      final eol = utils.endOfLine;
      final source = buildGetterSource(
        indent: indent,
        name: 'logTag',
        expression: expression,
        eol: eol,
      );
      await builder.addDartFileEdit(file, (builder) {
        builder.addReplacement(range.node(target.member), (builder) {
          builder.write(source);
        });
      });
      return;
    }

    final insertion = findInsertionTarget(classDeclaration, utils);
    if (insertion == null) {
      return;
    }

    final eol = utils.endOfLine;
    final source =
        '${insertion.leadingEol}'
        '${buildGetterSource(
          indent: insertion.indent,
          name: 'logTag',
          expression: expression,
          eol: eol,
        )}';

    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(insertion.offset, (builder) {
        builder.write(source);
      });
    });
  }
}

class SetLogGroupFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'grumpy.fix.setLogGroup',
    DartFixKindPriority.standard,
    'Set log group to the class name',
  );

  SetLogGroupFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final classDeclaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classDeclaration == null) {
      return;
    }
    final element = classDeclaration.declaredFragment?.element;
    if (element == null) {
      return;
    }

    final className = element.displayName;
    final useSuperGroup = isAbstractLogMixinSuper(element);
    final expression = expectedGroupExpression(
      className,
      useSuperGroup: useSuperGroup,
    );

    final target = findMemberTarget(classDeclaration, 'group');
    if (target?.expression != null) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addReplacement(range.node(target!.expression!), (builder) {
          builder.write(expression);
        });
      });
      return;
    }

    if (target != null) {
      final indent = utils.getLinePrefix(target.member.offset);
      final eol = utils.endOfLine;
      final source = buildGetterSource(
        indent: indent,
        name: 'group',
        expression: expression,
        eol: eol,
      );
      await builder.addDartFileEdit(file, (builder) {
        builder.addReplacement(range.node(target.member), (builder) {
          builder.write(source);
        });
      });
      return;
    }

    final insertion = findInsertionTarget(classDeclaration, utils);
    if (insertion == null) {
      return;
    }

    final eol = utils.endOfLine;
    final source =
        '${insertion.leadingEol}'
        '${buildGetterSource(
          indent: insertion.indent,
          name: 'group',
          expression: expression,
          eol: eol,
        )}';

    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(insertion.offset, (builder) {
        builder.write(source);
      });
    });
  }
}
