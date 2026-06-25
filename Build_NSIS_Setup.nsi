; ============================================================
; SourceGit 专用 NSIS 安装卸载脚本模板
; 特性：LZMA最高压缩、安装前强杀进程、旧版本全覆盖卸载、
;       管理员权限、控制面板标准卸载项、卸载自动清除用户配置
; 适用：SourceGit (Git GUI 客户端)
; ============================================================

; ===================== 1. 引入NSIS必备扩展头文件 =====================
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"
!include "x64.nsh"

; ===================== 2. 全局压缩配置 =====================
SetCompressionLevel 9
SetCompressor /SOLID LZMA

; ===================== 3. 图标配置（必须在 MUI 宏之前定义） =====================
!define MUI_ICON "SourceGit.ico"
!define MUI_UNICON "SourceGit.ico"
Icon "SourceGit.ico"

; ===================== 4. 【核心配置区】所有项目仅修改此处即可复用 =====================
!define APP_DISPLAY_NAME "SourceGit"
!define APP_NAME         "SourceGit"
!define APP_ID           "SourceGit.sourcegit-scm.com.github"
!define APP_EXE          "SourceGit.exe"
!define APP_VERSION      "2026.6.15.13"
!define APP_PUBLISHER    "SourceGit-SCM"
!define APP_WEBSITE      "https://github.com/sourcegit-scm/sourcegit"
!define DIST_DIR         "D:\Fsoft\SourceGit"
!define REG_KEY          "Software\${APP_ID}"
!define APP_DATA_PATH    "$APPDATA\${APP_ID}"

; ===================== 5. MUI界面头部横幅配置 =====================
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT

; ===================== 6. 安装包全局基础参数 =====================
Name "${APP_DISPLAY_NAME}"
OutFile "${APP_NAME}-win32-${APP_VERSION}.exe"
Unicode True
RequestExecutionLevel admin
ShowInstDetails show
ShowUnInstDetails show

; ===================== 7. 安装目录（初始占位，运行时动态调整） =====================
; 注意：此处仅提供默认值，实际将在 .onInit 中根据系统架构动态设置
InstallDir "$PROGRAMFILES\${APP_NAME}"
InstallDirRegKey HKLM "${REG_KEY}" "Install_Dir"

; ===================== 8. 安装包exe文件版本资源信息 =====================
VIProductVersion "${APP_VERSION}"
VIAddVersionKey "ProductName" "${APP_DISPLAY_NAME}"
VIAddVersionKey "CompanyName" "${APP_PUBLISHER}"
VIAddVersionKey "FileDescription" "${APP_DISPLAY_NAME} Setup Installer"
VIAddVersionKey "FileVersion" "${APP_VERSION}"
VIAddVersionKey "ProductVersion" "${APP_VERSION}"
VIAddVersionKey "LegalCopyright" "Copyright © ${APP_PUBLISHER}"
VIAddVersionKey "URLInfoAbout" "${APP_WEBSITE}"

; ===================== 9. MUI页面全局行为配置 =====================
!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\${APP_EXE}"
!define MUI_FINISHPAGE_RUN_TEXT "$(STR_RUN_AFTER)"
!define MUI_FINISHPAGE_RUN_CHECKED

; ===================== 10. 按顺序插入安装与卸载流程页面 =====================
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; ===================== 11. 加载语言包与自定义多语言字符串 =====================
!insertmacro MUI_LANGUAGE "SimpChinese"

LangString STR_DESKTOP ${LANG_SIMPCHINESE} "创建桌面快捷方式"
LangString STR_STARTMENU ${LANG_SIMPCHINESE} "创建开始菜单程序组"
LangString STR_RUN_AFTER ${LANG_SIMPCHINESE} "安装完成后立即启动程序"
LangString STR_UPGRADE ${LANG_SIMPCHINESE} "检测到旧版本，覆盖安装将替换全部文件，是否继续？"
LangString STR_UNINSTALL_TIP ${LANG_SIMPCHINESE} "卸载完成，程序文件已清理完毕。"
LangString STR_UNINSTALL_KEEP_CFG ${LANG_SIMPCHINESE} "是否保留用户配置文件？$\r$\n选择「是」保留配置，下次安装可恢复设置。$\r$\n选择「否」将同时清除所有用户数据。"
LangString STR_DELETE_OLD_FAILED ${LANG_SIMPCHINESE} "无法完全删除旧版本文件，请检查是否有程序仍在运行，然后重试。"

Var AlreadyInstalled

; ===================== 12. 安装前置初始化函数 .onInit =====================
Function .onInit
    ; 强制结束正在运行的进程（防止文件占用阻塞安装）
    nsExec::ExecToLog 'taskkill /f /im "${APP_EXE}" 2>NUL'
    Sleep 1000

    ; 根据运行时系统架构动态设置默认安装目录
    ${If} ${RunningX64}
        StrCpy $INSTDIR "$PROGRAMFILES64\${APP_NAME}"
    ${Else}
        StrCpy $INSTDIR "$PROGRAMFILES\${APP_NAME}"
    ${EndIf}

    ; 读取注册表中记录的旧安装路径
    ReadRegStr $AlreadyInstalled HKLM "${REG_KEY}" "Install_Dir"

    ; 没有旧版本则直接跳过升级逻辑
    ${If} $AlreadyInstalled == ""
        Goto OnInitDone
    ${EndIf}

    ; 校验旧路径是否真实存在（防注册表残留垃圾）
    ${IfNot} ${FileExists} "$AlreadyInstalled\*.*"
        StrCpy $AlreadyInstalled ""
        Goto OnInitDone
    ${EndIf}

    ; 弹出升级确认框
    MessageBox MB_YESNO|MB_ICONQUESTION "$(STR_UPGRADE)" IDYES DoUpgrade
    Abort

    DoUpgrade:
        ; 强制终止全部进程树
        nsExec::ExecToLog 'taskkill /f /t /im "${APP_EXE}" 2>NUL'
        Sleep 2000

        ; 最多重试 3 次删除旧目录
        StrCpy $R0 0
        ${Do}
            RMDir /r "$AlreadyInstalled"
            ${IfNot} ${Errors}
                ${ExitDo}
            ${EndIf}
            IntOp $R0 $R0 + 1
            Sleep 1000
        ${LoopUntil} $R0 >= 3

        ${If} ${Errors}
            MessageBox MB_OK|MB_ICONSTOP "无法删除旧版本文件（可能被其他程序占用），请手动关闭所有相关程序后重试。"
            Abort
        ${EndIf}

        ; 标记重启后残留清理，并将安装目录锁定到旧路径
        RMDir /REBOOTOK "$AlreadyInstalled"
        StrCpy $INSTDIR $AlreadyInstalled

    OnInitDone:
FunctionEnd
; ===================== 13. 【必选主程序安装区段】 =====================
Section "主程序文件" SecMain
    SectionIn RO

    SetOutPath "$INSTDIR"
    SetOverwrite on

    File /r "${DIST_DIR}\*"

    WriteUninstaller "$INSTDIR\uninstall.exe"

    WriteRegStr HKLM "${REG_KEY}" "Install_Dir" "$INSTDIR"
    WriteRegStr HKLM "${REG_KEY}" "Version" "${APP_VERSION}"

    ; ===== 控制面板卸载注册表项 =====
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "DisplayName" "${APP_DISPLAY_NAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "DisplayVersion" "${APP_VERSION}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "Publisher" "${APP_PUBLISHER}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "InstallLocation" "$INSTDIR"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "HelpLink" "${APP_WEBSITE}"
    ; 【优化】添加 DisplayIcon 使控制面板显示程序图标
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "DisplayIcon" "$INSTDIR\${APP_EXE}"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "NoModify" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "NoRepair" 1

    ; 计算安装大小（直接写入十进制）
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "EstimatedSize" $0
SectionEnd

; ===================== 14. 可选组件：桌面快捷方式 =====================
Section "$(STR_DESKTOP)" SecDesktop
    Delete "$DESKTOP\${APP_DISPLAY_NAME}.lnk"
    CreateShortcut "$DESKTOP\${APP_DISPLAY_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}"
SectionEnd

; ===================== 15. 可选组件：开始菜单程序组 =====================
Section "$(STR_STARTMENU)" SecStartMenu
    Delete "$SMPROGRAMS\${APP_DISPLAY_NAME}\*.lnk"
    CreateDirectory "$SMPROGRAMS\${APP_DISPLAY_NAME}"
    CreateShortcut "$SMPROGRAMS\${APP_DISPLAY_NAME}\${APP_DISPLAY_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}"
    CreateShortcut "$SMPROGRAMS\${APP_DISPLAY_NAME}\卸载 ${APP_DISPLAY_NAME}.lnk" "$INSTDIR\uninstall.exe"
SectionEnd

; ===================== 16. 全局卸载区段 =====================
Section "Uninstall"
    ; 保护：$INSTDIR 为空时跳过目录删除，防止误删驱动器根
    ${If} $INSTDIR == ""
        MessageBox MB_OK|MB_ICONSTOP "无法确定安装目录，请手动删除程序文件夹。"
        Abort
    ${EndIf}

    ; 强制结束进程
    nsExec::ExecToLog 'taskkill /f /im "${APP_EXE}" 2>NUL'
    Sleep 1000

    ; 询问是否保留用户配置
    MessageBox MB_YESNO|MB_ICONQUESTION "$(STR_UNINSTALL_KEEP_CFG)" IDNO PurgeConfig
    Goto AfterConfig

    PurgeConfig:
        RMDir /r "${APP_DATA_PATH}"
        RMDir /REBOOTOK "${APP_DATA_PATH}"

    AfterConfig:

    ; 删除桌面快捷方式
    Delete "$DESKTOP\${APP_DISPLAY_NAME}.lnk"
    ; 删除开始菜单快捷方式
    Delete "$SMPROGRAMS\${APP_DISPLAY_NAME}\*.lnk"
    RMDir "$SMPROGRAMS\${APP_DISPLAY_NAME}"

    ; 删除安装目录及文件
    RMDir /r "$INSTDIR"
    RMDir /REBOOTOK "$INSTDIR"

    ; 清理注册表
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}"
    DeleteRegKey HKLM "${REG_KEY}"

    MessageBox MB_OK|MB_ICONINFORMATION "$(STR_UNINSTALL_TIP)"
SectionEnd
