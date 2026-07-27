# NSIS 通用打包脚本使用指南

本脚本是一个基于 **NSIS (Nullsoft Scriptable Install System)** 和 **MUI2** 构建的高级安装包模板。适用于 Windows 桌面应用，具备首次安装向导、静默覆盖升级、非空目录风险拦截、自定义界面UI图片、强制杀进程及防解压运行等能力。

---

## 🛠️ 环境准备

1. **安装 NSIS 工具**：
    - 请下载并安装 [NSIS 3.x](https://nsis.sourceforge.io/) 或更高版本。
    - 建议安装 **Unicode** 版本以支持中文环境。
2. **准备必要文件**：
    - 软件产物目录（包含 `.exe` 主程序及依赖文件）。
    - 图标文件 `icon.ico`（与 `.nsi` 脚本放在同级目录）。
    - （可选）界面图片 `header.bmp` 和 `left.bmp`。
    - （可选）许可协议文件 `LICENSE`（纯文本格式）。

---

## ⚙️ 参数配置（脚本用户配置区）

打开 `.nsi` 脚本，修改开头的 **用户配置区** 宏定义：

```nsis
!define APP_DISPLAY_NAME "SourceGit"  ; 快捷方式及界面上显示的软件名称
!define APP_NAME         "SourceGit"  ; 注册表键值及安装文件夹名称
!define APP_ID           "com.github.SourceGit-scm.SourceGit" ; 全局唯一标识符
!define APP_EXE          "SourceGit.exe"  ; 软件主执行程序文件名
!define APP_VERSION      "2026.7.27.16"   ; 版本号（必须由 4 段数字组成）
!define APP_PUBLISHER    "[https://github.com/SourceGit-scm/](https://github.com/SourceGit-scm/)"   ; 发行商名称/链接
!define APP_WEBSITE      "[https://github.com/SourceGit-scm/SourceGit](https://github.com/SourceGit-scm/SourceGit)"  ; 项目官网链接

!define DIST_DIR         "D:\Fsoft\SourceGit" ; 待打包的产物绝对路径或相对路径
!define ICON_FILE        "icon.ico"  ; 图标路径


; --- 可选界面配置（取消注释即可启用） ---
!define LICENSE_FILE     "LICENSE"   ; 许可协议路径
!define HEADER_BITMAP     "header.bmp" ; 顶部标头图片
!define LEFT_BITMAP       "left.bmp"   ; 左侧侧边栏图片
```
