import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class AddRequiredConstructorCallFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'grumpy.fix.addRequiredConstructorCall',
    DartFixKindPriority.standard,
    'Call {0} in the constructor',
  );

  AddRequiredConstructorCallFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  List<String>? get fixArguments {
    final methodName = _methodName;
    return methodName == null ? null : [methodName];
  }

  String? get _methodName => _extractMethodName();

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final methodName = _methodName;
    if (methodName == null) {
      return;
    }

    final constructor = node.thisOrAncestorOfType<ConstructorDeclaration>();
    if (constructor == null) {
      return;
    }

    final body = constructor.body;
    if (body is BlockFunctionBody) {
      await _insertCallInBlock(builder, body, methodName);
      return;
    }

    if (body is EmptyFunctionBody) {
      await _replaceEmptyBody(builder, constructor, methodName);
    }
  }

  Future<void> _insertCallInBlock(
    ChangeBuilder builder,
    BlockFunctionBody body,
    String methodName,
  ) async {
    final block = body.block;
    final eol = utils.endOfLine;
    final indent = utils.getLinePrefix(block.rightBracket.offset) +
        utils.oneIndent;
    final between = utils.getText(
      block.leftBracket.end,
      block.rightBracket.offset - block.leftBracket.end,
    );
    final leadingEol =
        between.contains('\n') || between.contains('\r') ? '' : eol;
    final source = '$leadingEol$indent$methodName();$eol';

    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(block.rightBracket.offset, (builder) {
        builder.write(source);
      });
    });
  }

  Future<void> _replaceEmptyBody(
    ChangeBuilder builder,
    ConstructorDeclaration constructor,
    String methodName,
  ) async {
    final eol = utils.endOfLine;
    final constructorIndent = utils.getLinePrefix(constructor.offset);
    final statementIndent = constructorIndent + utils.oneIndent;
    final source =
        '{$eol$statementIndent$methodName();$eol$constructorIndent}';

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(constructor.body), (builder) {
        builder.write(source);
      });
    });
  }

  String? _extractMethodName() {
    final current = diagnostic;
    if (current == null) {
      return null;
    }

    final correction = current.correctionMessage;
    if (correction != null) {
      final match = RegExp(r'`([^`]+)`').firstMatch(correction);
      if (match != null) {
        return match.group(1);
      }
    }

    final message = current.message;
    final callMatch =
        RegExp(r'Call\s+([^\s]+)\s+in the constructor').firstMatch(message);
    if (callMatch != null) {
      return callMatch.group(1);
    }

    return null;
  }
}

class AddRequiredInitializerCallFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'grumpy.fix.addRequiredInitializerCall',
    DartFixKindPriority.standard,
    'Call {0} in the initializer',
  );

  AddRequiredInitializerCallFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  List<String>? get fixArguments {
    final methodName = _methodName;
    return methodName == null ? null : [methodName];
  }

  String? get _methodName => _extractMethodName();

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final methodName = _methodName;
    if (methodName == null) {
      return;
    }

    final method = node.thisOrAncestorOfType<MethodDeclaration>();
    if (method == null) {
      return;
    }

    final body = method.body;
    if (body is BlockFunctionBody) {
      await _insertCallInBlock(builder, body, methodName);
      return;
    }

    if (body is EmptyFunctionBody) {
      await _replaceEmptyBody(builder, method, methodName);
    }
  }

  Future<void> _insertCallInBlock(
    ChangeBuilder builder,
    BlockFunctionBody body,
    String methodName,
  ) async {
    final block = body.block;
    final eol = utils.endOfLine;
    final indent = utils.getLinePrefix(block.rightBracket.offset) +
        utils.oneIndent;
    final between = utils.getText(
      block.leftBracket.end,
      block.rightBracket.offset - block.leftBracket.end,
    );
    final leadingEol =
        between.contains('\n') || between.contains('\r') ? '' : eol;
    final source = '$leadingEol$indent$methodName();$eol';

    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(block.rightBracket.offset, (builder) {
        builder.write(source);
      });
    });
  }

  Future<void> _replaceEmptyBody(
    ChangeBuilder builder,
    MethodDeclaration method,
    String methodName,
  ) async {
    final eol = utils.endOfLine;
    final methodIndent = utils.getLinePrefix(method.offset);
    final statementIndent = methodIndent + utils.oneIndent;
    final source = '{$eol$statementIndent$methodName();$eol$methodIndent}';

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(method.body), (builder) {
        builder.write(source);
      });
    });
  }

  String? _extractMethodName() {
    final current = diagnostic;
    if (current == null) {
      return null;
    }

    final correction = current.correctionMessage;
    if (correction != null) {
      final match = RegExp(r'`([^`]+)`').firstMatch(correction);
      if (match != null) {
        return match.group(1);
      }
    }

    final message = current.message;
    final callMatch =
        RegExp(r'Call\s+([^\s]+)\s+in the initializer').firstMatch(message);
    if (callMatch != null) {
      return callMatch.group(1);
    }

    return null;
  }
}

class RemoveAbstractConstructorCallFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'grumpy.fix.removeAbstractConstructorCall',
    DartFixKindPriority.standard,
    'Remove {0} call from the constructor',
  );

  RemoveAbstractConstructorCallFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  List<String>? get fixArguments {
    final methodName = _methodName;
    return methodName == null ? null : [methodName];
  }

  String? get _methodName => _extractMethodName();

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final methodName = _methodName;
    if (methodName == null) {
      return;
    }

    final constructor = node.thisOrAncestorOfType<ConstructorDeclaration>();
    if (constructor == null) {
      return;
    }

    final body = constructor.body;
    if (body is! BlockFunctionBody) {
      return;
    }

    final statement = _findCallStatement(body.block, methodName);
    if (statement == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.nodeInList(body.block.statements, statement));
    });
  }

  ExpressionStatement? _findCallStatement(Block block, String methodName) {
    for (final statement in block.statements) {
      if (statement is! ExpressionStatement) {
        continue;
      }
      final expression = statement.expression;
      if (expression is! MethodInvocation) {
        continue;
      }
      if (expression.methodName.name != methodName) {
        continue;
      }
      return statement;
    }
    return null;
  }

  String? _extractMethodName() {
    final current = diagnostic;
    if (current == null) {
      return null;
    }

    final correction = current.correctionMessage;
    if (correction != null) {
      final match = RegExp(r'`([^`]+)`').firstMatch(correction);
      if (match != null) {
        return match.group(1);
      }
    }

    final message = current.message;
    final callMatch = RegExp(
      r'Do not call\s+([^\s]+)\s+in an abstract constructor',
    ).firstMatch(message);
    if (callMatch != null) {
      return callMatch.group(1);
    }

    return null;
  }
}

class RemoveAbstractInitializerCallFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'grumpy.fix.removeAbstractInitializerCall',
    DartFixKindPriority.standard,
    'Remove {0} call from the initializer',
  );

  RemoveAbstractInitializerCallFix({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  List<String>? get fixArguments {
    final methodName = _methodName;
    return methodName == null ? null : [methodName];
  }

  String? get _methodName => _extractMethodName();

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final methodName = _methodName;
    if (methodName == null) {
      return;
    }

    final method = node.thisOrAncestorOfType<MethodDeclaration>();
    if (method == null) {
      return;
    }

    final body = method.body;
    if (body is! BlockFunctionBody) {
      return;
    }

    final statement = _findCallStatement(body.block, methodName);
    if (statement == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.nodeInList(body.block.statements, statement));
    });
  }

  ExpressionStatement? _findCallStatement(Block block, String methodName) {
    for (final statement in block.statements) {
      if (statement is! ExpressionStatement) {
        continue;
      }
      final expression = statement.expression;
      if (expression is! MethodInvocation) {
        continue;
      }
      if (expression.methodName.name != methodName) {
        continue;
      }
      return statement;
    }
    return null;
  }

  String? _extractMethodName() {
    final current = diagnostic;
    if (current == null) {
      return null;
    }

    final correction = current.correctionMessage;
    if (correction != null) {
      final match = RegExp(r'`([^`]+)`').firstMatch(correction);
      if (match != null) {
        return match.group(1);
      }
    }

    final message = current.message;
    final callMatch = RegExp(
      r'Do not call\s+([^\s]+)\s+in an abstract initializer',
    ).firstMatch(message);
    if (callMatch != null) {
      return callMatch.group(1);
    }

    return null;
  }
}
