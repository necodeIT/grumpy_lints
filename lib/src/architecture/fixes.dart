import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:grumpy_lints/src/utils/const.dart';
import 'package:grumpy_lints/src/utils/superclass.dart';

class ExtendFix extends DartFix {
  final String className;
  final String imports;
  ExtendFix(this.className, [this.imports = kPackageImport]);

  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic analysisError,
    List<Diagnostic> others,
  ) {
    context.registry.addClassDeclaration((declaration) async {
      if (!analysisError.sourceRange.intersects(declaration.sourceRange)) {
        return;
      }

      final extendsService = declaration.anySuperclass(
        (element) => element.name == className,
      );

      if (extendsService) return;

      final unit = await resolver.getResolvedUnitResult();

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Extend $className',
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        _addExtendsClause(declaration, builder);
        _addServiceImport(unit.unit, builder);
      });
    });
  }

  void _addExtendsClause(
    ClassDeclaration declaration,
    DartFileEditBuilder builder,
  ) {
    final extendsText = 'extends $className';
    final existingExtends = declaration.extendsClause;

    if (existingExtends != null) {
      builder.addSimpleReplacement(
        SourceRange(existingExtends.offset, existingExtends.length),
        extendsText,
      );
      return;
    }

    final insertionOffset =
        declaration.withClause?.offset ??
        declaration.implementsClause?.offset ??
        declaration.leftBracket.offset;

    builder.addSimpleInsertion(insertionOffset, ' $extendsText ');
  }

  void _addServiceImport(CompilationUnit unit, DartFileEditBuilder builder) {
    final importUri = imports;

    final hasImport = unit.directives.any(
      (directive) =>
          directive is ImportDirective &&
          directive.uri.stringValue == importUri,
    );

    if (hasImport) return;

    final hasPartOf = unit.directives.any(
      (directive) => directive is PartOfDirective,
    );

    if (hasPartOf) return;

    final directives = unit.directives;
    var insertionOffset = 0;

    if (directives.isNotEmpty) {
      ImportDirective? lastImport;
      for (final directive in directives) {
        if (directive is ImportDirective) {
          lastImport = directive;
        }
      }

      insertionOffset = (lastImport ?? directives.last).end;
    }

    final prefix = insertionOffset == 0 ? '' : '\n';

    builder.addSimpleInsertion(
      insertionOffset,
      "${prefix}import '$importUri';\n",
    );
  }
}

class SuffixFix extends DartFix {
  final String suffix;

  SuffixFix(this.suffix);

  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic analysisError,
    List<Diagnostic> others,
  ) {
    context.registry.addClassDeclaration((declaration) {
      if (!analysisError.sourceRange.intersects(declaration.sourceRange)) {
        return;
      }

      final originalName = declaration.name.lexeme;
      final updatedName = _withSuffix(originalName);

      if (originalName == updatedName) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Rename to $updatedName',
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          SourceRange(declaration.name.offset, declaration.name.length),
          updatedName,
        );

        for (final constructor
            in declaration.members.whereType<ConstructorDeclaration>()) {
          _updateConstructorName(
            constructor,
            originalName,
            updatedName,
            builder,
          );
          _updateRedirectedConstructor(
            constructor,
            originalName,
            updatedName,
            builder,
          );
        }
      });
    });
  }

  String _withSuffix(String name) =>
      name.endsWith(suffix) ? name : '$name$suffix';

  void _updateConstructorName(
    ConstructorDeclaration constructor,
    String originalName,
    String updatedName,
    DartFileEditBuilder builder,
  ) {
    final returnType = constructor.returnType;
    if (returnType.name != originalName) return;

    builder.addSimpleReplacement(
      SourceRange(returnType.offset, returnType.length),
      updatedName,
    );
  }

  void _updateRedirectedConstructor(
    ConstructorDeclaration constructor,
    String originalName,
    String updatedName,
    DartFileEditBuilder builder,
  ) {
    final redirected = constructor.redirectedConstructor;
    if (redirected == null) return;

    final type = redirected.type;
    final redirectName = type.name.lexeme;
    if (redirectName != originalName) return;
    if (type.importPrefix != null) return;

    builder.addSimpleReplacement(
      SourceRange(type.name.offset, type.name.length),
      updatedName,
    );
  }
}
