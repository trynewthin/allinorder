# AllInOrder

我希望创建一个可以更舒服地管理项目的工具。

目前仍处于早期开发阶段，功能非常有限。

## Flutter 桌面应用

这是一个使用 Flutter 开发的桌面应用程序。

### 环境要求

Flutter SDK (>=3.0.0)
Windows 10 或更高版本
Visual Studio 2019 或更高版本（包含 Desktop development with C++）

### 安装步骤

确保您已安装 Flutter SDK 并正确配置环境变量
克隆此仓库
在项目根目录运行以下命令：
```
flutter pub get
flutter config --enable-windows-desktop
flutter run -d windows
```
### 功能特点

Material Design 3 界面设计
响应式布局
窗口管理
现代化用户界面

### 开发说明
本项目使用了以下主要依赖：

window_manager: 用于管理窗口属性
provider: 用于状态管理
flutter_lints: 代码规范检查

### 许可证
MIT License