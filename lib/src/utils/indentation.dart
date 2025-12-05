import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

String indentForNode(AstNode node, CustomLintResolver resolver) {
  return indentForOffset(resolver, node.offset);
}

String indentForOffset(CustomLintResolver resolver, int offset) {
  return _indentAtOffset(resolver.source.contents.data, offset);
}

String missingIndent(String targetIndent, String existingIndent) {
  if (targetIndent.length <= existingIndent.length) {
    return '';
  }
  return targetIndent.substring(existingIndent.length);
}

String indentForBlockStatement(Block block, CustomLintResolver resolver) {
  if (block.statements.isNotEmpty) {
    return indentForNode(block.statements.first, resolver);
  }

  final blockIndent =
      _indentAtOffset(resolver.source.contents.data, block.leftBracket.offset);
  return '$blockIndent  ';
}

String leadingNewlineForInsertion(
  Block block,
  CustomLintResolver resolver,
  int insertionOffset,
) {
  final content = resolver.source.contents.data;
  final snippet = content.substring(block.leftBracket.offset, insertionOffset);
  return snippet.contains('\n') || snippet.contains('\r') ? '' : '\n';
}

String _indentAtOffset(String content, int offset) {
  var lineStart = offset;
  while (lineStart > 0) {
    final char = content.codeUnitAt(lineStart - 1);
    if (char == 0x0A || char == 0x0D) {
      break;
    }
    lineStart--;
  }

  var indentEnd = lineStart;
  while (indentEnd < content.length) {
    final char = content.codeUnitAt(indentEnd);
    if (char == 0x20 || char == 0x09) {
      indentEnd++;
      continue;
    }
    break;
  }

  return content.substring(lineStart, indentEnd);
}
