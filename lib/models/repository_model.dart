import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../utils/platform_adapter.dart';
import 'project_model.dart';
import 'tag_model.dart';

class Repository {
  final String name;
  final String path;
  final List<Project> projects;
  final List<TagType> tagTypes;
  final Map<String, List<String>> tagsByType; // 每种类型的可用标签值

  Repository({
    required this.name,
    required this.path,
    List<Project>? projects,
    List<TagType>? tagTypes,
    Map<String, List<String>>? tagsByType,
  })  : projects = projects ?? [],
        tagTypes = tagTypes ?? [],
        tagsByType = tagsByType ?? {};

  static Future<Repository?> load(String directoryPath) async {
    final configDir = Directory(p.join(directoryPath, '.allinorder'));
    final configFile = File(p.join(configDir.path, 'configuration.json'));

    if (await configFile.exists()) {
      final jsonContent = await configFile.readAsString();
      final Map<String, dynamic> config = json.decode(jsonContent);

      List<Project> projects = [];
      if (config.containsKey('projects')) {
        final projectsList = config['projects'] as List;
        projects = projectsList
            .map((p) => Project.fromJson(p))
            .where((p) => p.exists())
            .toList();
      }

      List<TagType> tagTypes = [];
      if (config.containsKey('tagTypes')) {
        final tagTypesList = config['tagTypes'] as List;
        tagTypes = tagTypesList.map((t) => TagType.fromJson(t)).toList();
      }

      Map<String, List<String>> tagsByType = {};
      if (config.containsKey('tagsByType')) {
        final tagsMap = config['tagsByType'] as Map<String, dynamic>;
        tagsByType = tagsMap
            .map((key, value) => MapEntry(key, (value as List).cast<String>()));
      }

      return Repository(
        name: config['name'],
        path: directoryPath,
        projects: projects,
        tagTypes: tagTypes,
        tagsByType: tagsByType,
      );
    }
    return null;
  }

  static Future<Repository> initialize(
      String directoryPath, String name) async {
    final configDir = Directory(p.join(directoryPath, '.allinorder'));
    await configDir.create();

    final configFile = File(p.join(configDir.path, 'configuration.json'));
    final config = {
      'name': name,
      'projects': [],
      'tagTypes': [],
      'tagsByType': {},
    };

    await configFile.writeAsString(json.encode(config));

    return Repository(
      name: name,
      path: directoryPath,
    );
  }

  Future<void> _saveConfiguration() async {
    final configFile = File(p.join(path, '.allinorder', 'configuration.json'));
    final config = {
      'name': name,
      'projects': projects.map((p) => p.toJson()).toList(),
      'tagTypes': tagTypes.map((t) => t.toJson()).toList(),
      'tagsByType': tagsByType,
    };
    await configFile.writeAsString(json.encode(config));
  }

  Future<Project> createProject(String name, {Set<Tag>? tags}) async {
    if (tags != null) {
      // 验证标签类型是否有效
      for (final tag in tags) {
        final tagType = tagTypes.firstWhere(
          (t) => t.id == tag.type,
          orElse: () => throw Exception('无效的标签类型：${tag.type}'),
        );

        // 验证标签值是否有效
        if (!tagsByType[tag.type]!.contains(tag.name)) {
          throw Exception('无效的标签值：${tag.name}');
        }
      }

      // 验证必选标签类型
      final requiredTypes =
          tagTypes.where((t) => t.required).map((t) => t.id).toSet();
      final providedTypes = tags.map((t) => t.type).toSet();
      final missingTypes = requiredTypes.difference(providedTypes);
      if (missingTypes.isNotEmpty) {
        throw Exception('缺少必需的标签类型：${missingTypes.join(', ')}');
      }

      // 验证多选限制
      final tagCounts = <String, int>{};
      for (final tag in tags) {
        tagCounts[tag.type] = (tagCounts[tag.type] ?? 0) + 1;
      }
      for (final type in tagCounts.keys) {
        final tagType = tagTypes.firstWhere((t) => t.id == type);
        if (!tagType.multiSelect && tagCounts[type]! > 1) {
          throw Exception('标签类型 ${tagType.name} 不允许多选');
        }
      }
    }

    final project = await Project.create(
      name: name,
      repositoryPath: path,
      tags: tags,
    );

    projects.add(project);
    await _saveConfiguration();
    return project;
  }

  Future<void> deleteProject(Project project) async {
    // 删除项目文件夹
    final directory = Directory(project.path);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }

    // 从列表中移除
    projects.removeWhere((p) => p.id == project.id);

    // 保存配置
    await _saveConfiguration();
  }

  Future<void> updateProject(Project project) async {
    final index = projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      projects[index] = project;
      await _saveConfiguration();
    }
  }

  Future<void> addTagType(TagType tagType, List<String> allowedValues) async {
    if (tagTypes.any((t) => t.id == tagType.id)) {
      throw Exception('标签类型ID已存在');
    }
    tagTypes.add(tagType);
    tagsByType[tagType.id] = allowedValues;
    await _saveConfiguration();
  }

  Future<void> updateTagType(
      TagType tagType, List<String> allowedValues) async {
    final index = tagTypes.indexWhere((t) => t.id == tagType.id);
    if (index == -1) {
      throw Exception('标签类型不存在');
    }
    tagTypes[index] = tagType;
    tagsByType[tagType.id] = allowedValues;
    await _saveConfiguration();
  }

  Future<void> deleteTagType(String typeId) async {
    // 检查是否有项目使用了这个标签类型
    if (projects.any((p) => p.tags.any((t) => t.type == typeId))) {
      throw Exception('无法删除正在使用的标签类型');
    }
    tagTypes.removeWhere((t) => t.id == typeId);
    tagsByType.remove(typeId);
    await _saveConfiguration();
  }

  List<Project> findProjectsByTags(Set<Tag> tags) {
    return projects
        .where((p) => tags.every((tag) => p.tags.contains(tag)))
        .toList();
  }

  Set<Tag> getAllTags() {
    return projects.expand((p) => p.tags).toSet();
  }

  List<Tag> getTagsByType(String typeId) {
    return getAllTags().where((t) => t.type == typeId).toList();
  }
}
