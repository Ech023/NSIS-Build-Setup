; ============================================================
; SourceGit 专用 NSIS 安装卸载脚本模板
; 特性：LZMA最高压缩、安装前强杀进程、旧版本全覆盖卸载、
;       管理员权限、控制面板标准卸载项、卸载自动清除用户配置
; 适用：SourceGit (Git GUI 客户端)
; ============================================================

; ===================== 1. 引入NSIS必备扩展头文件 =====================
!include "MUI2.nsh"      ; 现代美观的 MUI2 图形安装界面（主流标准界面库）
!include "LogicLib.nsh"  ; 逻辑扩展库，提供 ${If} ${Else} 高级条件判断语法
!include "FileFunc.nsh"  ; 文件操作扩展库，用于计算安装目录占用大小
!include "x64.nsh"       ; 64位系统兼容库，自动区分32/64位 ProgramFiles 路径

; ===================== 2. 全局压缩配置 =====================
SetCompressionLevel 9     ; LZMA压缩等级，范围0~9，9为最高压缩率
SetCompressor /SOLID LZMA ; 启用 Solid 固实 LZMA 压缩，整体压缩，体积最小

; ===================== 3. 图标配置 (必须在 MUI 宏之前定义) =====================
; 【重要】请确保编译时，当前目录下存在 SourceGit.ico 文件。
; 如果路径包含中文，请务必使用绝对路径（如 "D:\MyProject\SourceGit.ico"）
!define MUI_ICON "SourceGit.ico"      ; 安装程序自身的 exe 图标
!define MUI_UNICON "SourceGit.ico"    ; 卸载程序的 exe 图标
Icon "SourceGit.ico"                  ; 安装界面左上角的小图标

; ===================== 4. 【核心配置区】所有项目仅修改此处即可复用 =====================
!define APP_DISPLAY_NAME "SourceGit" 
; 程序对外显示名称（安装窗口标题、控制面板卸载列表、快捷方式名称）

!define APP_NAME         "SourceGit"         
; 程序内部短名称（用作安装文件夹名、最终安装包exe文件名前缀）

!define APP_ID           "SourceGit.sourcegit-scm.com.github"   
; 程序唯一全局标识（注册表存储路径核心值，禁止和其他软件重复）

!define APP_EXE          "SourceGit.exe"          
; 程序主可执行文件名称（安装目录根目录必须存在该exe）

!define APP_VERSION      "2026.6.15.13"                 
; 对外展示版本号（格式 X.X.X.X，四段纯数字，适配VIProductVersion校验）

!define APP_PUBLISHER    "SourceGit-SCM" 
; 开发商/发布者名称（写入exe文件属性、控制面板）

!define APP_WEBSITE      "https://github.com/sourcegit-scm/sourcegit" 
; 软件官方网址（控制面板卸载页面显示的帮助链接）

!define DIST_DIR          "D:\Fsoft\SourceGit"                   
; 【修改点】待打包资源根目录路径（编译前请确保路径正确且包含exe）

!define REG_KEY           "Software\${APP_ID}"  
; 注册表自定义安装信息存储根路径，用于记录安装目录、版本号

!define APP_DATA_PATH "$APPDATA\${APP_ID}"
; 用户配置存储目录（卸载时整体删除，对齐 SourceGit 官方文档路径）

; ===================== 5. MUI界面头部横幅配置 =====================
!define MUI_HEADERIMAGE       ; 启用安装页面顶部右侧横幅图片
!define MUI_HEADERIMAGE_RIGHT ; 将横幅图片居右对齐显示

; ===================== 6. 安装包全局基础参数 =====================
Name "${APP_DISPLAY_NAME}"                          ; 安装程序窗口标题文本
OutFile "${APP_NAME}-win32-${APP_VERSION}.exe"      ; 编译输出的安装包文件名
Unicode True                                        ; 启用Unicode编码，完美支持中文路径
RequestExecutionLevel admin                         ; 请求管理员权限运行（写入ProgramFiles必须）
ShowInstDetails show                                ; 安装过程窗口：默认展开详细日志
ShowUnInstDetails show                              ; 卸载过程窗口：默认展开详细日志

; ===================== 7. 自动适配32/64位系统安装目录 =====================
!ifdef X64
    InstallDir "$PROGRAMFILES64\${APP_NAME}" ; 64位系统默认路径
!else
    InstallDir "$PROGRAMFILES\${APP_NAME}"   ; 32位系统默认路径
!endif
InstallDirRegKey HKLM "${REG_KEY}" "Install_Dir" ; 从注册表读取旧路径，方便覆盖升级

; ===================== 8. 安装包exe文件版本资源信息（右键exe→属性→详细信息） =====================
VIProductVersion "${APP_VERSION}"                
VIAddVersionKey "ProductName" "${APP_DISPLAY_NAME}"
VIAddVersionKey "CompanyName" "${APP_PUBLISHER}"
VIAddVersionKey "FileDescription" "${APP_DISPLAY_NAME} Setup Installer"
VIAddVersionKey "FileVersion" "${APP_VERSION}"       
VIAddVersionKey "ProductVersion" "${APP_VERSION}"    
VIAddVersionKey "LegalCopyright" "Copyright © ${APP_PUBLISHER}"
VIAddVersionKey "URLInfoAbout" "${APP_WEBSITE}"

; ===================== 9. MUI页面全局行为配置 =====================
!define MUI_ABORTWARNING                             ; 用户点击取消时弹出确认框
!define MUI_FINISHPAGE_RUN "$INSTDIR\${APP_EXE}"     ; 安装完成页“运行程序”的目标路径
!define MUI_FINISHPAGE_RUN_TEXT "$(STR_RUN_AFTER)"   ; 运行程序复选框的显示文字
!define MUI_FINISHPAGE_RUN_CHECKED                   ; 默认勾选运行程序

; ===================== 10. 按顺序插入安装与卸载流程页面 =====================
!insertmacro MUI_PAGE_WELCOME      ; 1. 欢迎介绍页
!insertmacro MUI_PAGE_COMPONENTS   ; 2. 组件选择页（桌面快捷方式、开始菜单可选）
!insertmacro MUI_PAGE_DIRECTORY    ; 3. 安装目录选择页
!insertmacro MUI_PAGE_INSTFILES    ; 4. 核心安装进度页
!insertmacro MUI_PAGE_FINISH       ; 5. 安装完成结束页

!insertmacro MUI_UNPAGE_WELCOME    ; 卸载欢迎页
!insertmacro MUI_UNPAGE_CONFIRM    ; 卸载确认弹窗页
!insertmacro MUI_UNPAGE_INSTFILES  ; 卸载文件删除进度页
!insertmacro MUI_UNPAGE_FINISH     ; 卸载完成结束页

; ===================== 11. 加载语言包与自定义多语言字符串 =====================
!insertmacro MUI_LANGUAGE "SimpChinese"

LangString STR_DESKTOP ${LANG_SIMPCHINESE} "创建桌面快捷方式"
LangString STR_STARTMENU ${LANG_SIMPCHINESE} "创建开始菜单程序组"
LangString STR_RUN_AFTER ${LANG_SIMPCHINESE} "安装完成后立即启动程序"
LangString STR_UPGRADE ${LANG_SIMPCHINESE} "检测到旧版本，覆盖安装将替换全部文件，是否继续？"
LangString STR_UNINSTALL_TIP ${LANG_SIMPCHINESE} "卸载完成，程序目录与用户配置文件已全部清理完毕"

Var AlreadyInstalled ; 全局变量：存储从注册表读取到的旧版本安装路径

; ===================== 新增 12. 自定义函数：强制关闭程序进程 =====================
Function KillAppProcess
    ; 使用 nsExec 扩展执行命令，静默模式 (/c) 强制 ( /f) 结束进程
    ; 2>NUL 用于屏蔽系统找不到进程时的报错信息，保持界面干净
    nsExec::ExecToLog 'taskkill /f /im "${APP_EXE}" 2>NUL'
    
    ; 休眠 1000毫秒 (1秒)，给系统足够时间释放文件句柄
    ; 这对于覆盖正在运行的程序文件至关重要
    Sleep 1000
FunctionEnd

; ===================== 12. 安装前置初始化函数 .onInit =====================
Function .onInit

    Call KillAppProcess
    
    ; 读取注册表中记录的旧安装路径
    ReadRegStr $AlreadyInstalled HKLM "${REG_KEY}" "Install_Dir"
    
    ; 判断：如果注册表存在安装路径，说明已安装旧版本
    ${If} $AlreadyInstalled != ""
        ; 弹出是/否确认框，询问是否覆盖旧版本
        MessageBox MB_YESNO|MB_ICONQUESTION "$(STR_UPGRADE)" IDYES UpgradeGo
        ; 如果用户选择“否”，直接终止安装（此时进程已被杀，软件保持原状）
        Abort 
        
        UpgradeGo:
            ; 分步删除旧目录，/REBOOTOK 防止文件被占用时卸载失败
            RMDir /r "$AlreadyInstalled"
            RMDir /REBOOTOK "$AlreadyInstalled"
            ; 将本次安装目录强制赋值为旧目录，实现无缝覆盖升级
            StrCpy $INSTDIR $AlreadyInstalled
    ${EndIf}
FunctionEnd

; ===================== 13. 组件页面默认勾选项 =====================
!define MUI_COMPONENTSPAGE_DEFAULTS "SecDesktop SecStartMenu"

; ===================== 14. 【必选主程序安装区段】SectionIn RO 代表不可取消 =====================
Section "主程序文件" SecMain
    SectionIn RO ; 固定必装，用户无法取消勾选
    
    SetOutPath "$INSTDIR"      ; 设置当前文件输出根目录
    SetOverwrite ifnewer       ; 仅当打包内文件比本地旧文件更新时才覆盖
    
    ; 递归复制资源目录下所有文件，完整参与LZMA压缩
    File /r "${DIST_DIR}\*"

    ; 在安装目录生成卸载程序 uninstall.exe
    WriteUninstaller "$INSTDIR\uninstall.exe"
    
    ; 写入自定义安装信息到HKLM注册表（供升级时读取）
    WriteRegStr HKLM "${REG_KEY}" "Install_Dir" "$INSTDIR"
    WriteRegStr HKLM "${REG_KEY}" "Version" "${APP_VERSION}"
    
    ; ===================== Windows 控制面板「程序和功能」标准卸载注册表项 =====================
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "DisplayName" "${APP_DISPLAY_NAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "DisplayVersion" "${APP_VERSION}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "Publisher" "${APP_PUBLISHER}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "InstallLocation" "$INSTDIR"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "HelpLink" "${APP_WEBSITE}"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "NoModify" 1 ; 隐藏「更改」按钮
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "NoRepair" 1 ; 隐藏「修复」按钮
    
    ; 计算安装目录总占用大小（单位KB），用于控制面板展示软件尺寸
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    IntFmt $0 "0x%08X" $0                   
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "EstimatedSize" $0
SectionEnd

; ===================== 15. 可选组件：桌面快捷方式 =====================
Section "$(STR_DESKTOP)" SecDesktop
    Delete "$DESKTOP\${APP_DISPLAY_NAME}.lnk" ; 先删旧快捷方式防缓存残留
    ; 创建桌面快捷方式（第四个参数传入exe路径，自动提取exe内置图标）
    CreateShortcut "$DESKTOP\${APP_DISPLAY_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}"
SectionEnd

; ===================== 16. 可选组件：开始菜单程序组 =====================
Section "$(STR_STARTMENU)" SecStartMenu
    Delete "$SMPROGRAMS\${APP_DISPLAY_NAME}\*.lnk"
    CreateDirectory "$SMPROGRAMS\${APP_DISPLAY_NAME}"
    CreateShortcut "$SMPROGRAMS\${APP_DISPLAY_NAME}\${APP_DISPLAY_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}"
    CreateShortcut "$SMPROGRAMS\${APP_DISPLAY_NAME}\卸载 ${APP_DISPLAY_NAME}.lnk" "$INSTDIR\uninstall.exe"
SectionEnd

; ===================== 17. 全局卸载区段（执行卸载时全部逻辑） =====================
Section "Uninstall"
    ; 卸载前强制关闭运行中的程序，释放文件占用
    ExecWait 'taskkill /f /im "${APP_EXE}"'
    Sleep 1000 ; 短暂休眠等待进程退出
    
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
