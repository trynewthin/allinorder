import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/repository_model.dart';
import '../models/settings_model.dart';
import '../widgets/custom_app_bar.dart';
import 'repository_detail_page.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  Repository? _currentRepository;
  bool _isLoading = true;
  bool _isProcessing = false;
  late Settings _settings;

  @override
  void initState() {
    super.initState();
    _loadLastRepository();
  }

  Future<void> _loadLastRepository() async {
    try {
      _settings = await Settings.load();
      final repository = await _settings.loadLastRepository();

      if (mounted && repository != null) {
        setState(() {
          _currentRepository = repository;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RepositoryDetailPage(repository: repository),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await _handleError(context, '加载上次打开的仓库时发生错误：$e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleError(BuildContext context, String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _openRepository(Repository repository) async {
    setState(() {
      _currentRepository = repository;
    });
    await _settings.setLastRepositoryPath(repository.path);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RepositoryDetailPage(repository: repository),
      ),
    );
  }

  Future<void> _selectExistingRepository() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择仓库文件夹',
      );

      if (!mounted) return;

      if (selectedDirectory == null) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final repository = await Repository.load(selectedDirectory);
      if (repository != null) {
        // 是现有仓库
        setState(() {
          _isProcessing = false;
        });
        await _openRepository(repository);
      } else {
        // 不是仓库，询问是否初始化
        if (!mounted) return;
        final bool? shouldInitialize = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('初始化仓库'),
            content: const Text('选择的文件夹不是一个仓库。是否要将其初始化为新仓库？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确定'),
              ),
            ],
          ),
        );

        if (shouldInitialize == true) {
          final directory = Directory(selectedDirectory);
          final repository = await Repository.initialize(
            selectedDirectory,
            directory.path.split(Platform.pathSeparator).last,
          );
          setState(() {
            _isProcessing = false;
          });
          await _openRepository(repository);
        } else {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (!mounted) return;
      await _handleError(context, '选择文件夹时发生错误：$e');
    }
  }

  Future<void> _createNewRepository() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择新仓库位置',
      );

      if (!mounted) return;

      if (selectedDirectory == null) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final String? repositoryName = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('新建仓库'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '仓库名称',
                hintText: '请输入仓库名称',
              ),
              autofocus: true,
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('确定'),
              ),
            ],
          );
        },
      );

      if (repositoryName != null && repositoryName.isNotEmpty) {
        final newDirectory = Directory(
            '$selectedDirectory${Platform.pathSeparator}$repositoryName');
        if (await newDirectory.exists()) {
          if (!mounted) return;
          await _handleError(context, '文件夹"$repositoryName"已存在，请选择其他名称');
          setState(() {
            _isProcessing = false;
          });
          return;
        }

        await newDirectory.create();
        final repository = await Repository.initialize(
          newDirectory.path,
          repositoryName,
        );
        setState(() {
          _isProcessing = false;
        });
        await _openRepository(repository);
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (!mounted) return;
      await _handleError(context, '创建仓库时发生错误：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'ALL IN ORDER'),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'ALL IN ORDER'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'All In Order',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            if (_isProcessing)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _selectExistingRepository,
                    child: const Text('打开仓库'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _createNewRepository,
                    child: const Text('新建仓库'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
