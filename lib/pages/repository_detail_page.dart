import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/repository_model.dart';
import '../models/settings_model.dart';
import '../models/project_model.dart';
import '../models/tag_model.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/create_project_dialog.dart';
import 'projects_page.dart';
import 'settings_page.dart';

class RepositoryDetailPage extends StatefulWidget {
  final Repository repository;

  const RepositoryDetailPage({
    super.key,
    required this.repository,
  });

  @override
  State<RepositoryDetailPage> createState() => _RepositoryDetailPageState();
}

class _RepositoryDetailPageState extends State<RepositoryDetailPage> {
  late Settings _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settings = await Settings.load();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _closeRepository() async {
    await _settings.setLastRepositoryPath(null);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ProjectsPage(),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  Future<void> _createProject() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CreateProjectDialog(
        tagTypes: widget.repository.tagTypes,
        tagsByType: widget.repository.tagsByType,
      ),
    );

    if (result != null) {
      try {
        final project = await widget.repository.createProject(
          result['name'] as String,
          tags: result['tags'] as Set<Tag>,
        );
        setState(() {});
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建项目失败: $e')),
        );
      }
    }
  }

  Widget _buildToolbar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 工具按钮
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.addProject,
            onPressed: _createProject,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: () {
              setState(() {}); // 刷新项目列表
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: l10n.sort,
            onPressed: () {
              // TODO: 实现排序功能
            },
          ),
          const Spacer(),
          // 搜索框
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchProjects,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onChanged: (value) {
                // TODO: 实现搜索功能
              },
            ),
          ),
          const SizedBox(width: 8),
          // 菜单按钮
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: l10n.moreOptions,
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  _openSettings();
                  break;
                case 'close':
                  _closeRepository();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings),
                    const SizedBox(width: 8),
                    Text(l10n.settings),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'close',
                child: Row(
                  children: [
                    const Icon(Icons.logout),
                    const SizedBox(width: 8),
                    Text(l10n.closeRepository),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsContainer() {
    if (widget.repository.projects.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text('点击左上角的添加按钮创建新项目'),
        ),
      );
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListView.builder(
          itemCount: widget.repository.projects.length,
          itemBuilder: (context, index) {
            final project = widget.repository.projects[index];
            return ListTile(
              title: Text(project.name),
              subtitle: Text(project.path),
              trailing: Wrap(
                spacing: 8,
                children: project.tags.map((tag) {
                  final tagType = widget.repository.tagTypes
                      .firstWhere((t) => t.id == tag.type);
                  return Chip(
                    label: Text('${tagType.name}: ${tag.name}'),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(title: widget.repository.name),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(title: widget.repository.name),
      body: Column(
        children: [
          _buildToolbar(),
          _buildProjectsContainer(),
        ],
      ),
    );
  }
}
