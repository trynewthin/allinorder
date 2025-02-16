import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../utils/platform_adapter.dart';
import 'tag_model.dart';

class Project {
  final String id;
  final String name;
  final String path;
  final Set<Tag> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.name,
    required this.path,
    Set<Tag>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : tags = tags ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  static String _generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(5, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  static String _generateProjectPath(
      String repositoryPath, String name, String id) {
    return PlatformAdapter.joinPaths([repositoryPath, '${name}_$id']);
  }

  static Future<Project> create({
    required String name,
    required String repositoryPath,
    Set<Tag>? tags,
  }) async {
    final id = _generateId();
    final path = _generateProjectPath(repositoryPath, name, id);
    final directory = Directory(path);

    if (await directory.exists()) {
      throw Exception('项目目录已存在');
    }

    await directory.create(recursive: true);

    return Project(
      id: id,
      name: name,
      path: path,
      tags: tags ?? {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'tags': tags.map((tag) => tag.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      path: json['path'],
      tags: (json['tags'] as List).map((t) => Tag.fromJson(t)).toSet(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  bool exists() {
    return Directory(path).existsSync();
  }

  Project copyWith({
    String? name,
    Set<Tag>? tags,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      path: path,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // 获取特定类型的标签
  Set<Tag> getTagsByType(String type) {
    return tags.where((tag) => tag.type == type).toSet();
  }

  // 检查是否有重复类型的标签
  bool hasConflictingTags(Set<Tag> newTags) {
    final existingTypes = tags.map((t) => t.type).toSet();
    final newTypes = newTags.map((t) => t.type).toSet();
    return existingTypes.intersection(newTypes).isNotEmpty;
  }

  // 添加标签（确保每种类型只有一个）
  Project addTags(Set<Tag> newTags) {
    if (hasConflictingTags(newTags)) {
      throw Exception('不能添加重复类型的标签');
    }
    return copyWith(tags: tags.union(newTags));
  }

  // 移除标签
  Project removeTags(Set<Tag> tagsToRemove) {
    return copyWith(tags: tags.difference(tagsToRemove));
  }

  // 替换特定类型的标签
  Project replaceTagsByType(String type, Set<Tag> newTags) {
    if (!newTags.every((tag) => tag.type == type)) {
      throw Exception('新标签必须都是同一类型');
    }
    final remainingTags = tags.where((tag) => tag.type != type).toSet();
    return copyWith(tags: remainingTags.union(newTags));
  }
}
