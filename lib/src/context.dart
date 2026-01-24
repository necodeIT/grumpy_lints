import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/file_system/file_system.dart';

enum ProjectType { flutter, dart }

class GrumpyContext {
  final ProjectType projectType;

  final Map<Layer, List<Module>> modules;
  final Module rootModule;

  const GrumpyContext({
    required this.projectType,
    required this.modules,
    required this.rootModule,
  });
}

class Layer {
  final Module module;
  final String name;

  const Layer(this.name, this.module);

  const Layer.presentation(this.module) : name = 'presentation';
  const Layer.domain(this.module) : name = 'domain';
  const Layer.infra(this.module) : name = 'infrastructure';
}

class Service {
  final String name;
  final Layer layer;

  const Service(this.layer, this.name);
}

class Datasource {
  final Layer layer;
  final String name;

  const Datasource(this.layer, this.name);
}

class Module {
  final String name;
  final List<Service> services;
  final List<Datasource> datasources;
  final List<Module> imports;

  const Module(
    this.name, {
    this.services = const [],
    this.datasources = const [],
    this.imports = const [],
  });
}

class GrumpyContextBuilder {
  const GrumpyContextBuilder();

  GrumpyContext build(RuleContext context) {
    final packageRoot = _findPackageRoot(context);
    final projectType = _inferProjectType(packageRoot);
    final moduleRoot = _findModuleRoot(packageRoot);
    final modulesByLayer = <Layer, List<Module>>{};
    final modules = <Module>[];

    if (moduleRoot != null && moduleRoot.exists) {
      for (final child in moduleRoot.getChildren()) {
        if (child is! Folder) {
          continue;
        }
        if (!_looksLikeModule(child)) {
          continue;
        }
        final module = _buildModule(child);
        modules.add(module);
        _indexLayers(modulesByLayer, module, child);
      }
    }

    return GrumpyContext(
      projectType: projectType,
      modules: modulesByLayer,
      rootModule: _selectRootModule(modules),
    );
  }

  Folder _findPackageRoot(RuleContext context) {
    final fromContext = context.package?.root;
    if (fromContext != null) {
      return fromContext;
    }
    final start = context.definingUnit.file.parent;
    var current = start;
    while (true) {
      final pubspec = current.getChildAssumingFile('pubspec.yaml');
      if (pubspec.exists) {
        return current;
      }
      if (current.isRoot) {
        return start;
      }
      current = current.parent;
    }
  }

  ProjectType _inferProjectType(Folder packageRoot) {
    final pubspec = packageRoot.getChildAssumingFile('pubspec.yaml');
    if (!pubspec.exists) {
      return ProjectType.dart;
    }
    final content = pubspec.readAsStringSync();
    if (content.contains(RegExp(r'^\s*flutter\s*:', multiLine: true))) {
      return ProjectType.flutter;
    }
    return ProjectType.dart;
  }

  Folder? _findModuleRoot(Folder packageRoot) {
    final provider = packageRoot.provider;
    final pathContext = provider.pathContext;
    final libSrc = provider.getFolder(
      pathContext.join(packageRoot.path, 'lib', 'src'),
    );
    if (libSrc.exists) {
      return libSrc;
    }
    final lib = provider.getFolder(pathContext.join(packageRoot.path, 'lib'));
    if (lib.exists) {
      return lib;
    }
    return null;
  }

  bool _looksLikeModule(Folder folder) {
    final domain = folder.getChildAssumingFolder('domain');
    final infra = folder.getChildAssumingFolder('infra');
    final infrastructure = folder.getChildAssumingFolder('infrastructure');
    final presentation = folder.getChildAssumingFolder('presentation');
    return domain.exists ||
        infra.exists ||
        infrastructure.exists ||
        presentation.exists;
  }

  Module _buildModule(Folder moduleRoot) {
    final services = <Service>[];
    final datasources = <Datasource>[];
    final module = Module(
      moduleRoot.shortName,
      services: services,
      datasources: datasources,
      imports: const [],
    );

    _collectLayerEntries(
      moduleRoot: moduleRoot,
      layer: Layer.domain(module),
      services: services,
      datasources: datasources,
      layerFolder: 'domain',
    );
    _collectLayerEntries(
      moduleRoot: moduleRoot,
      layer: Layer.infra(module),
      services: services,
      datasources: datasources,
      layerFolder: 'infra',
    );
    _collectLayerEntries(
      moduleRoot: moduleRoot,
      layer: Layer.infra(module),
      services: services,
      datasources: datasources,
      layerFolder: 'infrastructure',
    );

    return module;
  }

  void _collectLayerEntries({
    required Folder moduleRoot,
    required Layer layer,
    required List<Service> services,
    required List<Datasource> datasources,
    required String layerFolder,
  }) {
    final servicesDir =
        moduleRoot.getChildAssumingFolder('$layerFolder/services');
    final datasourcesDir =
        moduleRoot.getChildAssumingFolder('$layerFolder/datasources');

    for (final name in _collectDartBaseNames(servicesDir)) {
      services.add(Service(layer, name));
    }
    for (final name in _collectDartBaseNames(datasourcesDir)) {
      datasources.add(Datasource(layer, name));
    }
  }

  List<String> _collectDartBaseNames(Folder folder) {
    if (!folder.exists) {
      return const [];
    }
    final results = <String>[];
    for (final child in folder.getChildren()) {
      if (child is Folder) {
        results.addAll(_collectDartBaseNames(child));
        continue;
      }
      if (child is! File) {
        continue;
      }
      final name = child.shortName;
      if (!name.endsWith('.dart')) {
        continue;
      }
      if (name.endsWith('.g.dart') || name.endsWith('.freezed.dart')) {
        continue;
      }
      final base = name.substring(0, name.length - '.dart'.length);
      if (base == 'services' || base == 'datasources') {
        continue;
      }
      results.add(_toPascalCase(base));
    }
    return results;
  }

  String _toPascalCase(String name) {
    final parts = name.split(RegExp(r'[_\-\s]+'));
    final buffer = StringBuffer();
    for (final part in parts) {
      if (part.isEmpty) {
        continue;
      }
      buffer.write(part[0].toUpperCase());
      if (part.length > 1) {
        buffer.write(part.substring(1));
      }
    }
    return buffer.toString();
  }

  void _indexLayers(
    Map<Layer, List<Module>> modulesByLayer,
    Module module,
    Folder moduleRoot,
  ) {
    void addIfExists(String layerName, Layer layer) {
      final folder = moduleRoot.getChildAssumingFolder(layerName);
      if (!folder.exists) {
        return;
      }
      modulesByLayer.putIfAbsent(layer, () => <Module>[]).add(module);
    }

    addIfExists('presentation', Layer.presentation(module));
    addIfExists('domain', Layer.domain(module));
    addIfExists('infra', Layer.infra(module));
    addIfExists('infrastructure', Layer.infra(module));
  }

  Module _selectRootModule(List<Module> modules) {
    if (modules.isEmpty) {
      return const Module('unknown');
    }
    for (final module in modules) {
      final name = module.name.toLowerCase();
      if (name == 'app' || name == 'root') {
        return module;
      }
    }
    return modules.first;
  }
}
