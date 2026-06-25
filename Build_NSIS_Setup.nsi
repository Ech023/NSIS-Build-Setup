; ============================================================
; NSIS 通用 Windows 程序安装卸载脚本模板
; 特性：LZMA最高压缩、安装前强杀进程、旧版本全覆盖卸载、管理员权限、控制面板标准卸载项
; 新增：卸载自动清除 %APPDATA% 下用户配置目录
; ============================================================

; ===================== 引入NSIS必备扩展头文件 =====================
!include "MUI2.nsh"      ; 现代美观MUI2图形安装界面（主流标准界面库）
!include "LogicLib.nsh"  ; 逻辑扩展库，提供 ${If} ${Else} 高级条件判断语法
!include "FileFunc.nsh"  ; 文件操作扩展库，用于计算安装目录占用大小（控制面板展示软件尺寸）
!include "x64.nsh"       ; 64位系统兼容库，自动区分32/64位ProgramFiles安装路径

; ===================== 全局压缩配置 =====================
SetCompressionLevel 9     ; LZMA压缩等级，范围0~9，9为最高压缩率（打包体积最小，编译稍慢）
SetCompressor /SOLID LZMA ; 启用Solid固实LZMA压缩，整体压缩，比普通LZMA压缩率提升20%~40%
!define COMPRESS_SOLID    ; 全局标记，后续脚本可判断是否开启固实压缩（本模板预留扩展用）

; ===================== 【核心配置区 - 所有项目仅修改此处即可复用模板】 =====================
!define APP_DISPLAY_NAME "SourceGit" 
; 程序对外显示名称：安装窗口标题、控制面板卸载列表、快捷方式名称均读取此变量

!define APP_NAME         "SourceGit"         
; 程序内部短名称：用作安装文件夹名、最终安装包exe文件名前缀，建议纯英文无空格

!define APP_ID           "SourceGit.sourcegit-scm.com.github"   
; 程序唯一全局标识：注册表存储路径核心值，用于区分多版本、多软件，禁止和其他软件重复

!define APP_EXE          "SourceGit.exe"          
; 程序主可执行文件名称，安装目录根目录必须存在该exe

!define APP_VERSION      "2026.6.15.13"                 
; 对外展示版本号，格式 X.X.X.X，四段纯数字适配VIProductVersion校验

!define APP_PUBLISHER    "https://github.com/sourcegit-scm" 
; 开发商/发布者名称，写入exe文件属性、控制面板

!define APP_WEBSITE      "https://github.com/sourcegit-scm/sourcegit" 
; 软件官方网址，控制面板卸载页面显示帮助链接

!define DIST_DIR          "D:\build\dist\SourceGit"                   
; 待打包资源根目录路径：可填写绝对路径如 D:\build\dist

!define REG_KEY           "Software\${APP_ID}"  
; 注册表自定义安装信息存储根路径，用于记录安装目录、版本号，实现升级读取旧路径

!define APP_DATA_PATH "$APPDATA\${APP_ID}"
; 用户配置存储目录：%APPDATA% 下软件专属文件夹，卸载时整体删除

; ===================== MUI界面头部横幅配置（仅支持bmp/png位图，无ico相关代码） =====================
!define MUI_HEADERIMAGE       ; 启用安装页面顶部右侧横幅图片
!define MUI_HEADERIMAGE_RIGHT ; 将横幅图片居右对齐显示

; ===================== 安装包全局基础参数 =====================
Name "${APP_DISPLAY_NAME}"                         
; 安装程序窗口标题文本

OutFile "${APP_NAME}-win32-${APP_VERSION}.exe"     
; 编译输出的安装包文件名，自动拼接名称+架构+版本

Unicode True                                       
; 启用Unicode编码，完美支持中文路径、中文文件名、中文文字，禁止ANSI模式

RequestExecutionLevel admin                        
; 请求管理员权限运行：写入ProgramFiles系统目录、读写HKLM注册表必须管理员权限

ShowInstDetails show                               
; 安装过程窗口：默认展开文件复制详细日志
ShowUnInstDetails show                             
; 卸载过程窗口：默认展开文件删除详细日志

; ===================== 自动适配32/64位系统安装目录 =====================
!ifdef X64
    ; 64位系统：32位程序默认安装至 Program Files (x86)
    InstallDir "$PROGRAMFILES64\${APP_NAME}"
!else
    ; 32位系统：安装至 Program Files
    InstallDir "$PROGRAMFILES\${APP_NAME}"
!endif

InstallDirRegKey HKLM "${REG_KEY}" "Install_Dir"
; 从注册表读取上一次安装路径，用户再次安装时目录选择页自动填充旧路径，方便覆盖升级

; ===================== 安装包exe文件版本资源信息（右键安装包exe→属性→详细信息） =====================
VIProductVersion "${APP_VERSION}"                
; 【强制四段纯数字】Windows资源版本号校验入口，带字母直接编译报错

VIAddVersionKey "ProductName" "${APP_DISPLAY_NAME}"
VIAddVersionKey "CompanyName" "${APP_PUBLISHER}"
VIAddVersionKey "FileDescription" "${APP_DISPLAY_NAME} Setup Installer"
VIAddVersionKey "FileVersion" "${APP_VERSION}"       ; 文件版本
VIAddVersionKey "ProductVersion" "${APP_VERSION}"    ; 产品版本
VIAddVersionKey "LegalCopyright" "Copyright © ${APP_PUBLISHER}"
VIAddVersionKey "URLInfoAbout" "${APP_WEBSITE}"

; ===================== MUI页面全局行为配置 =====================
!define MUI_ABORTWARNING                            
; 用户点击窗口取消/关闭按钮时，弹出确认提示框，防止误关闭安装

!define MUI_FINISHPAGE_RUN "$INSTDIR\${APP_EXE}"    
; 安装完成页面：复选框运行程序的目标exe完整路径

!define MUI_FINISHPAGE_RUN_TEXT "$(STR_RUN_AFTER)"  
; 安装完成页“运行程序”复选框显示文字（读取多语言字符串）

!define MUI_FINISHPAGE_RUN_CHECKED                  
; 安装完成页“运行程序”复选框默认勾选状态

; ===================== 按顺序插入安装流程页面 =====================
!insertmacro MUI_PAGE_WELCOME      ; 1. 欢迎介绍页
!insertmacro MUI_PAGE_COMPONENTS  ; 2. 组件选择页（桌面快捷方式、开始菜单分组可选）
!insertmacro MUI_PAGE_DIRECTORY   ; 3. 安装目录选择页
!insertmacro MUI_PAGE_INSTFILES   ; 4. 核心安装进度页（文件复制、注册表写入）
!insertmacro MUI_PAGE_FINISH      ; 5. 安装完成结束页

; ===================== 按顺序插入卸载流程页面 =====================
!insertmacro MUI_UNPAGE_WELCOME   ; 卸载欢迎页
!insertmacro MUI_UNPAGE_CONFIRM   ; 卸载确认弹窗页
!insertmacro MUI_UNPAGE_INSTFILES ; 卸载文件删除进度页
!insertmacro MUI_UNPAGE_FINISH    ; 卸载完成结束页

; ===================== 加载语言包（简体中文） =====================
!insertmacro MUI_LANGUAGE "SimpChinese"

; ===================== 多语言自定义文本字符串 =====================
; 语法：LangString 字符串名 语言ID "显示文本"
LangString STR_DESKTOP ${LANG_SIMPCHINESE} "创建桌面快捷方式"
LangString STR_STARTMENU ${LANG_SIMPCHINESE} "创建开始菜单程序组"
LangString STR_RUN_AFTER ${LANG_SIMPCHINESE} "安装完成后立即启动程序"
LangString STR_UPGRADE ${LANG_SIMPCHINESE} "检测到旧版本，覆盖安装将替换全部文件，是否继续？"
; 修改提示：告知用户配置文件同步删除
LangString STR_UNINSTALL_TIP ${LANG_SIMPCHINESE} "卸载完成，程序目录与用户配置文件已全部清理完毕"

Var AlreadyInstalled 
; 全局变量：存储从注册表读取到的旧版本安装路径，用于升级覆盖判断

; ===================== 安装前置初始化函数 .onInit（安装程序启动第一时间执行） =====================
Function .onInit
    ; 强制杀掉正在运行的主程序进程，避免文件占用导致升级覆盖失败
    ExecWait 'taskkill /f /im "${APP_EXE}"'
    Sleep 1000 ; 休眠1秒，等待进程完全释放文件句柄
    
    ; 读取注册表中记录的旧安装路径
    ReadRegStr $AlreadyInstalled HKLM "${REG_KEY}" "Install_Dir"
    
    ; 判断：如果注册表存在安装路径 = 已安装旧版本
    ${If} $AlreadyInstalled != ""
        ; 弹出是/否确认框，询问是否覆盖旧版本
        MessageBox MB_YESNO|MB_ICONQUESTION "$(STR_UPGRADE)" IDYES UpgradeGo
        Abort ; 用户选择“否”，直接终止整个安装流程
        
        UpgradeGo:
            ; 分步删除旧目录（NSIS官方RMDir不支持同时携带/r + /REBOOTOK，拆分两行执行）
            RMDir /r "$AlreadyInstalled"
            RMDir /REBOOTOK "$AlreadyInstalled"
            ; 将本次安装目录强制赋值为旧目录，实现覆盖升级
            StrCpy $INSTDIR $AlreadyInstalled
    ${EndIf}
FunctionEnd

; ===================== 组件页面默认勾选项 =====================
!define MUI_COMPONENTSPAGE_DEFAULTS "SecDesktop SecStartMenu"

; ===================== 【必选主程序安装区段】SectionIn RO 代表不可取消 =====================
Section "主程序文件" SecMain
    SectionIn RO ; RO=Read Only，固定必装，用户无法取消勾选
    
    SetOutPath "$INSTDIR"      ; 设置当前文件输出根目录为用户选择的安装目录
    SetOverwrite ifnewer       ; 文件覆盖策略：仅当打包内文件比本地旧文件更新时才覆盖
    
    ; 递归复制资源目录下所有文件、子文件夹，完整参与LZMA压缩
    File /r "${DIST_DIR}\*"

    ; 在安装目录生成卸载程序 uninstall.exe（卸载功能核心文件，必须生成）
    WriteUninstaller "$INSTDIR\uninstall.exe"
    
    ; 写入自定义安装信息到HKLM注册表（升级时读取）
    WriteRegStr HKLM "${REG_KEY}" "Install_Dir" "$INSTDIR"
    WriteRegStr HKLM "${REG_KEY}" "Version" "${APP_VERSION}"
    
    ; ===================== Windows 控制面板「程序和功能」标准卸载注册表项 =====================
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "DisplayName" "${APP_DISPLAY_NAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "DisplayVersion" "${APP_VERSION}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "Publisher" "${APP_PUBLISHER}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "InstallLocation" "$INSTDIR"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "UninstallString" '"$INSTDIR\uninstall.exe"' ; 卸载程序完整启动命令
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "HelpLink" "${APP_WEBSITE}"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "NoModify" 1 ; 隐藏控制面板「更改」按钮
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "NoRepair" 1 ; 隐藏控制面板「修复」按钮
    
    ; 计算安装目录总占用大小（单位KB），用于控制面板展示软件尺寸
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    IntFmt $0 "0x%08X" $0                   ; 转换为Windows标准16进制存储格式
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "EstimatedSize" $0
SectionEnd

; ===================== 可选组件：桌面快捷方式 =====================
Section "$(STR_DESKTOP)" SecDesktop
    ; 先删除旧快捷方式，防止图标缓存残留
    Delete "$DESKTOP\${APP_DISPLAY_NAME}.lnk"
    ; 创建桌面快捷方式（仅传路径，无任何ico图标参数，使用系统默认图标）
    CreateShortcut "$DESKTOP\${APP_DISPLAY_NAME}.lnk" "$INSTDIR\${APP_EXE}"
SectionEnd

; ===================== 可选组件：开始菜单程序组 =====================
Section "$(STR_STARTMENU)" SecStartMenu
    ; 清理历史残留快捷方式
    Delete "$SMPROGRAMS\${APP_DISPLAY_NAME}\*.lnk"
    ; 在开始菜单创建专属程序文件夹
    CreateDirectory "$SMPROGRAMS\${APP_DISPLAY_NAME}"
    ; 创建主程序启动快捷方式
    CreateShortcut "$SMPROGRAMS\${APP_DISPLAY_NAME}\${APP_DISPLAY_NAME}.lnk" "$INSTDIR\${APP_EXE}"
    ; 创建卸载程序快捷方式，用户可直接从开始菜单卸载软件
    CreateShortcut "$SMPROGRAMS\${APP_DISPLAY_NAME}\卸载 ${APP_DISPLAY_NAME}.lnk" "$INSTDIR\uninstall.exe"
SectionEnd

; ===================== 全局卸载区段（执行卸载时全部逻辑） =====================
Section "Uninstall"
    ; 卸载前强制关闭运行中的程序，释放文件占用
    ExecWait 'taskkill /f /im "${APP_EXE}"'
    Sleep 500 ; 短暂休眠等待进程退出
    
    ; 删除桌面快捷方式
    Delete "$DESKTOP\${APP_DISPLAY_NAME}.lnk"
    ; 删除开始菜单分组内所有快捷方式
    Delete "$SMPROGRAMS\${APP_DISPLAY_NAME}\*.lnk"
    ; 删除开始菜单程序文件夹（仅文件夹为空时才删除）
    RMDir "$SMPROGRAMS\${APP_DISPLAY_NAME}"
    
    ; 【新增】递归删除 %APPDATA% 下用户配置目录
    RMDir /r "${APP_DATA_PATH}"
    RMDir /REBOOTOK "${APP_DATA_PATH}"
    
    ; 分段递归删除完整程序安装目录，规避RMDir多参数语法限制
    RMDir /r "$INSTDIR"
    RMDir /REBOOTOK "$INSTDIR"
    
    ; 清理控制面板卸载注册表项
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}"
    ; 清理自定义安装信息注册表项
    DeleteRegKey HKLM "${REG_KEY}"
    
    ; 全部删除完成后弹出提示框
    MessageBox MB_OK|MB_ICONINFORMATION "$(STR_UNINSTALL_TIP)"
SectionEnd