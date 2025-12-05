import 'package:analyzer/dart/ast/ast.dart';

extension CallsMethodExtension on Block {
  bool callsMethodAtEnd(String methodName) {
    if (statements.isEmpty) return false;

    final lastStatement = statements.last;
    if (lastStatement is ExpressionStatement) {
      final expression = lastStatement.expression;
      if (expression is MethodInvocation) {
        return expression.methodName.name == methodName;
      }
    }
    return false;
  }

  bool callsMethodAnywhere(String methodName) {
    for (final statement in statements) {
      if (statement is ExpressionStatement) {
        final expression = statement.expression;
        if (expression is MethodInvocation) {
          if (expression.methodName.name == methodName) {
            return true;
          }
        }
      }
    }
    return false;
  }
}
