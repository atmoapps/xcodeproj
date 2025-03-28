part of pbx;

mixin PBXTargetMixin on PBXElement {
  /// A reference to a [XCConfigurationList] element
  XCConfigurationList? get buildConfigurationList =>
      project.getObject(get('buildConfigurationList')) as XCConfigurationList?;

  /// A list of references to [PBXBuildPhase] elements
  List<PBXBuildPhase> get buildPhases => getObjectList('buildPhases');

  /// A list of references to [PBXTargetDependency] elements
  List<PBXTargetDependency> get dependencies => getObjectList('dependencies');

  /// The name of the target
  String get name => get('name');

  /// The product name
  String get productName => get('productName');

  /// Add Run script into Xcode "Build Phase".
  void addRunScript({
    required String name,
    required String shellScript,
    List<String> files = const [],
    List<String> inputFileListPaths = const [],
    List<String> inputsPaths = const [],
    List<String> outputPaths = const [],
    List<String> outputFileListPaths = const [],
    String shellPath = '/bin/sh',
    bool showEnvVarsInLog = true, // 'Show environment variables in build log' default checked (null - not visible)
    String? dependencyFile, // Default 'discovered dependency file' option unchecked (null - not visible)
    bool alwaysOutOfDate = true, // 'Based on dependency analysis' default checked (null - not visible)
  }) {
    const buildActionMask = 2147483647; // buildActionMask is const (compatible) for this below parameter
    const runOnlyForDeploymentPostprocessing = 0; // install build only = false (unchecked)

    var uuid = UuidGenerator().random();

    project.set('objects/$uuid', {
      'isa': 'PBXShellScriptBuildPhase',
      'name': name,
      'alwaysOutOfDate': alwaysOutOfDate ? null : 1, // this is not an error, xCode set flag 1 if this value unchecked
      'buildActionMask': buildActionMask,
      'files': files,
      'inputFileListPaths': inputFileListPaths,
      'inputPaths': inputsPaths,
      'outputFileListPaths': outputFileListPaths,
      'outputPaths': outputPaths,
      'shellPath': shellPath,
      'shellScript': shellScript,
      'runOnlyForDeploymentPostprocessing': runOnlyForDeploymentPostprocessing,
      'showEnvVarsInLog': showEnvVarsInLog ? null : 0, // this is not an error, xCode set flag 0 if this value unchecked
      'dependencyFile': dependencyFile,
    });

    var p = 'objects/${this.uuid}/buildPhases';
    project.set(p, [...getList('buildPhases'), uuid]);
  }

  /// Remove Run script with proper [name] from Xcode "Build Phase", and also the reference.
  /// Return true if script existed and now it doesn't, otherwise false.
  bool removeRunScript(String name) {
    var isRemoved = false;

    final buildPhasesListString = [...getList('buildPhases')];

    // list uuid which is the same as 'name' parameter
    final uuidToDeleted = buildPhases.whereType<PBXShellScriptBuildPhase>().where((element) => element.name == name).map((e) => e.uuid);

    if (uuidToDeleted.isNotEmpty) {
      isRemoved = true;
    }

    // Remove run script object (with all parameters)
    for (final uuid in uuidToDeleted) {
      buildPhasesListString.removeWhere((element) => (element as String) == uuid);
      project.set('objects/$uuid', null);
    }

    // Remove UUIDs from buildPhases list (reference)
    var p = 'objects/$uuid/buildPhases';
    project.set(p, buildPhasesListString);

    return isRemoved;
  }

  void addFramework(String path, String sourceTree) {
    var frameworks = project.groups.where((group) => group.name == 'Frameworks').single;

    var reference = frameworks.children.where((file) => file.path == path);
    if (reference.isEmpty) {
      var file = frameworks.addReference(path, sourceTree: sourceTree);
      var phase = buildPhases.where((phase) => phase.runtimeType == PBXFrameworksBuildPhase).single as PBXFrameworksBuildPhase;
      phase.linkBinaryWithFile(file);
    }
  }
}

abstract class PBXTarget = PBXElement with PBXTargetMixin;

mixin PBXAggregateTargetMixin on PBXTarget {}

/// Element for a build target that aggregates several others
class PBXAggregateTarget = PBXTarget with PBXAggregateTargetMixin;

mixin PBXLegacyTargetMixin on PBXTarget {}

class PBXLegacyTarget = PBXTarget with PBXLegacyTargetMixin;

mixin PBXNativeTargetMixin on PBXTarget {
  /// The product install path.
  String get productInstallPath => get('productInstallPath');

  /// A reference to a [PBXFileReference] element
  PBXFileReference? get productReference =>
      project.getObject(get('productReference')) as PBXFileReference?;

  /// See the PBXProductType enumeration
  String get productType => get('productType');
}

/// Element for a build target that produces a binary content (application or
/// library).
class PBXNativeTarget = PBXTarget with PBXNativeTargetMixin;

mixin PBXTargetDependencyMixin on ChildSnapshotView implements PBXElement {
  /// A reference to a [PBXNativeTarget] element.
  String get target => get('target');

  /// A reference to a [PBXContainerItemProxy] element.
  String get targetProxy => get('targetProxy');
}

/// Element for referencing other target through content proxies.
class PBXTargetDependency = PBXElement with PBXTargetDependencyMixin;
