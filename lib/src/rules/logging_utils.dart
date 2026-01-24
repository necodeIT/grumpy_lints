import 'package:analysis_server_plugin/edit/correction_utils.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

const _logMixinName = 'LogMixin';
const _superGroupInterpolation = r'${super.group}';

class MemberTarget {
  final ClassMember member;
  final Expression? expression;

  const MemberTarget(this.member, this.expression);
}

class InsertionTarget {
  final int offset;
  final String indent;
  final String leadingEol;

  const InsertionTarget(this.offset, this.indent, this.leadingEol);
}

bool usesLogMixin(ClassElement element) {
  if (element.mixins.any((type) => _isLogMixinElement(type.element))) {
    return true;
  }
  return element.allSupertypes.any((type) => _isLogMixinElement(type.element));
}

bool isAbstractLogMixinSuper(ClassElement element) {
  final supertype = element.supertype;
  if (supertype == null) {
    return false;
  }
  final superElement = supertype.element;
  if (superElement is! ClassElement) {
    return false;
  }
  if (!superElement.isAbstract) {
    return false;
  }
  return usesLogMixin(superElement);
}

MemberTarget? findMemberTarget(ClassDeclaration node, String name) {
  final body = node.body;
  if (body is! BlockClassBody) {
    return null;
  }
  for (final member in body.members) {
    if (member is MethodDeclaration &&
        member.isGetter &&
        !member.isStatic &&
        member.name.lexeme == name) {
      return MemberTarget(member, _getterExpression(member));
    }
    if (member is FieldDeclaration && !member.isStatic) {
      for (final field in member.fields.variables) {
        if (field.name.lexeme == name) {
          return MemberTarget(member, field.initializer);
        }
      }
    }
  }
  return null;
}

bool matchesLogTag(Expression? expression, String className) {
  return _matchesLiteral(expression, className);
}

bool matchesGroup(
  Expression? expression,
  String className, {
  required bool useSuperGroup,
}) {
  if (!useSuperGroup) {
    return _matchesLiteral(expression, className);
  }
  if (expression is! StringInterpolation) {
    return false;
  }
  return _matchesSuperGroupInterpolation(expression, className);
}

String expectedLogTagExpression(String className) => "'$className'";

String expectedGroupExpression(
  String className, {
  required bool useSuperGroup,
}) {
  if (!useSuperGroup) {
    return "'$className'";
  }
  return "'$_superGroupInterpolation.$className'";
}

InsertionTarget? findInsertionTarget(
  ClassDeclaration node,
  CorrectionUtils utils,
) {
  final body = node.body;
  if (body is! BlockClassBody) {
    return null;
  }

  final members = body.members;
  int anchorOffset;
  String indent;
  if (members.isEmpty) {
    anchorOffset = body.leftBracket.end;
    final classIndent = utils.getLinePrefix(node.offset);
    indent = '$classIndent${utils.oneIndent}';
  } else {
    final lastMember = members.last;
    anchorOffset = lastMember.end;
    indent = utils.getLinePrefix(lastMember.offset);
  }

  final insertionOffset = utils.getLineContentEnd(anchorOffset);
  final between = utils.getText(anchorOffset, insertionOffset - anchorOffset);
  final hasEol = between.contains('\n') || between.contains('\r');
  final leadingEol = hasEol ? '' : utils.endOfLine;

  return InsertionTarget(insertionOffset, indent, leadingEol);
}

String buildGetterSource({
  required String indent,
  required String name,
  required String expression,
  required String eol,
}) {
  return '$indent@override$eol'
      '${indent}String get $name => $expression;$eol';
}

Expression? _getterExpression(MethodDeclaration member) {
  final body = member.body;
  if (body is ExpressionFunctionBody) {
    return body.expression;
  }
  if (body is BlockFunctionBody) {
    final statements = body.block.statements;
    if (statements.length == 1 && statements.first is ReturnStatement) {
      final statement = statements.first as ReturnStatement;
      return statement.expression;
    }
  }
  return null;
}

bool _matchesLiteral(Expression? expression, String expected) {
  return expression is SimpleStringLiteral && expression.value == expected;
}

bool _matchesSuperGroupInterpolation(
  StringInterpolation interpolation,
  String className,
) {
  final elements = interpolation.elements;
  if (elements.isEmpty) {
    return false;
  }

  var index = 0;
  if (elements[index] is InterpolationString) {
    final prefix = (elements[index] as InterpolationString).value;
    if (prefix.isNotEmpty) {
      return false;
    }
    index++;
  }

  if (index >= elements.length) {
    return false;
  }

  final expressionElement = elements[index];
  if (expressionElement is! InterpolationExpression ||
      !_isSuperGroupAccess(expressionElement.expression)) {
    return false;
  }
  index++;

  if (index >= elements.length) {
    return false;
  }

  final suffixElement = elements[index];
  if (suffixElement is! InterpolationString ||
      suffixElement.value != '.$className') {
    return false;
  }
  index++;

  if (index == elements.length) {
    return true;
  }

  if (index == elements.length - 1) {
    final tail = elements[index];
    return tail is InterpolationString && tail.value.isEmpty;
  }

  return false;
}

bool _isLogMixinElement(InterfaceElement element) {
  return element.displayName == _logMixinName;
}

bool _isSuperGroupAccess(Expression expression) {
  return expression is PropertyAccess &&
      expression.target is SuperExpression &&
      expression.propertyName.name == 'group';
}
