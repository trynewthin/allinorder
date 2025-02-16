import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/tag_model.dart';

class CreateProjectDialog extends StatefulWidget {
  final List<TagType> tagTypes;
  final Map<String, List<String>> tagsByType;

  const CreateProjectDialog({
    super.key,
    required this.tagTypes,
    required this.tagsByType,
  });

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _nameController = TextEditingController();
  final _selectedTags = <String, Set<String>>{}; // type -> tag names
  String? _nameError;

  @override
  void initState() {
    super.initState();
    // 初始化每个标签类型的选择集合
    for (final type in widget.tagTypes) {
      _selectedTags[type.id] = {};
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addTag(String typeId, String tagName) {
    final tagType = widget.tagTypes.firstWhere((t) => t.id == typeId);
    if (!tagType.multiSelect && _selectedTags[typeId]!.isNotEmpty) {
      _selectedTags[typeId]!.clear();
    }
    setState(() {
      _selectedTags[typeId]!.add(tagName);
    });
  }

  void _removeTag(String typeId, String tagName) {
    setState(() {
      _selectedTags[typeId]!.remove(tagName);
    });
  }

  bool _validateTags() {
    // 检查必选标签类型
    for (final type in widget.tagTypes) {
      if (type.required && _selectedTags[type.id]!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('请选择${type.name}')),
        );
        return false;
      }
    }
    return true;
  }

  void _validateAndSubmit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameError = '项目名称不能为空';
      });
      return;
    }

    if (!_validateTags()) {
      return;
    }

    // 转换为Tag对象集合
    final tags = <Tag>{};
    for (final typeId in _selectedTags.keys) {
      for (final tagName in _selectedTags[typeId]!) {
        tags.add(Tag(name: tagName, type: typeId));
      }
    }

    Navigator.of(context).pop({
      'name': name,
      'tags': tags,
    });
  }

  Widget _buildTagTypeSection(TagType type) {
    final selectedTags = _selectedTags[type.id]!;
    final availableTags = widget.tagsByType[type.id]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              type.name + (type.required ? ' *' : ''),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (type.description.isNotEmpty) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: type.description,
                child: const Icon(Icons.info_outline, size: 16),
              ),
            ],
          ],
        ),
        if (type.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              type.description,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ...selectedTags.map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () => _removeTag(type.id, tag),
                )),
            PopupMenuButton<String>(
              child: Chip(
                label: const Text('添加'),
                avatar: const Icon(Icons.add, size: 16),
              ),
              itemBuilder: (context) {
                return availableTags
                    .where((tag) => !selectedTags.contains(tag))
                    .map((tag) => PopupMenuItem(
                          value: tag,
                          child: Text(tag),
                        ))
                    .toList();
              },
              onSelected: (tag) => _addTag(type.id, tag),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.addProject),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '项目名称',
                  errorText: _nameError,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (_nameError != null) {
                    setState(() {
                      _nameError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              ...widget.tagTypes.map(_buildTagTypeSection),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _validateAndSubmit,
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}
