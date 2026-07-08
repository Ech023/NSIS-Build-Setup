!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"
!include "x64.nsh"
; 保存格式为 utf-8 Bom 不然可能显示乱码
; ------------------- 压缩设置 -------------------
SetCompressionLevel 9
SetCompressor /SOLID LZMA

!define APP_DISPLAY_NAME "SourceGit"        ; 显示名称（用于界面、快捷方式）
!define APP_NAME         "SourceGit"        ; 技术名称（用于文件名、注册表键）
!define APP_ID           "SourceGit.sourcegit-scm.com.github"; 名称ID（推荐使用网站倒序）
!define APP_EXE          "SourceGit.exe"    ; 主程序文件名
!define APP_VERSION      "2026.6.15.13"     ; 版本号（必须四段数字）
!define APP_PUBLISHER    "SourceGit-SCM"
!define APP_WEBSITE      "https://github.com/sourcegit-scm/sourcegit"

; !!! 重要：将 DIST_DIR 修改为您的构建输出目录
!define DIST_DIR         "D:\Fsoft\SourceGit"   ; 示例路径，请替换为实际路径


; ------------------- 输出文件名 -------------------
OutFile "${APP_NAME}-win32-${APP_VERSION}.exe"
BrandingText ""   ; 移除版本提示
Name "${APP_DISPLAY_NAME}"
Icon "SourceGit.ico"                         ; 请将 SourceGit.ico 放在脚本同目录

; ------------------- 文件版本信息（右键属性） -------------------
VIProductVersion "${APP_VERSION}"
VIAddVersionKey "ProductName"     "${APP_DISPLAY_NAME}"
VIAddVersionKey "CompanyName"     "${APP_PUBLISHER}"
VIAddVersionKey "FileDescription" "${APP_DISPLAY_NAME} Installer"
VIAddVersionKey "FileVersion"     "${APP_VERSION}"
VIAddVersionKey "ProductVersion"  "${APP_VERSION}"
VIAddVersionKey "LegalCopyright"  "Copyright © ${APP_PUBLISHER}"
VIAddVersionKey "URLInfoAbout"    "${APP_WEBSITE}"

; ------------------- 默认安装路径 -------------------
!ifdef X64
  !define INSTALL_DIR_DEFAULT "$PROGRAMFILES64\${APP_NAME}"
!else
  !define INSTALL_DIR_DEFAULT "$PROGRAMFILES\${APP_NAME}"
!endif

; ------------------- 注册表键 -------------------
!define REG_ROOT          "HKLM"
!define REG_KEY_APP       "Software\${APP_ID}"
!define REG_KEY_UNINST    "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}"

; ------------------- MUI 界面样式 -------------------
!define MUI_ICON "SourceGit.ico"
!define MUI_UNICON "SourceGit.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\${APP_EXE}"
!define MUI_FINISHPAGE_RUN_TEXT "启动 $(^Name)"
!define MUI_FINISHPAGE_RUN_CHECKED

; ------------------- 页面定义 -------------------
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_COMPONENTS

; 目录页（带预检查和离开检查）
!define MUI_PAGE_CUSTOMFUNCTION_PRE DirectoryPagePre
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE DirectoryPageLeave
!insertmacro MUI_PAGE_DIRECTORY
!define MUI_PAGE_CUSTOMFUNCTION_PRE LicensePagePre
!insertmacro MUI_PAGE_LICENSE "Readme.txt"; 保存格式为 utf-8 Bom 不然可能显示乱码
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; 卸载页面
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; ------------------- 语言与本地化字符串 -------------------
!insertmacro MUI_LANGUAGE "SimpChinese"

LangString STR_DESKTOP    ${LANG_SIMPCHINESE} "创建桌面快捷方式"
LangString STR_STARTMENU  ${LANG_SIMPCHINESE} "创建开始菜单程序组"
LangString STR_RUN_AFTER  ${LANG_SIMPCHINESE} "安装完成后立即启动程序"
LangString STR_UNINSTALL_KEEP_CFG ${LANG_SIMPCHINESE} "是否保留用户配置文件？$\r$\n选择「是」保留配置，下次安装可恢复设置。$\r$\n选择「否」将同时清除所有用户数据。"
LangString STR_DIR_NOT_EMPTY ${LANG_SIMPCHINESE} "目标目录不为空！$\r$\n卸载时将删除整个目录，请确认该目录仅包含本应用的文件。$\r$\n是否继续？"
LangString STR_UPGRADE_ASK ${LANG_SIMPCHINESE} "检测到旧版本安装在：$\r$\n$OldInstallPath$\r$\n是否覆盖升级？$\r$\n（选择「否」将退出安装程序）"

; ------------------- 全局变量 -------------------
Var IsUpgradeMode
Var OldInstallPath

Function LicensePagePre
    ${If} $IsUpgradeMode == 1
        Abort
    ${EndIf}
FunctionEnd

; ============================================================
; 安装初始化
; ============================================================
Function .onInit
    StrCpy $IsUpgradeMode 0
    StrCpy $OldInstallPath ""
    ReadRegStr $OldInstallPath ${REG_ROOT} "${REG_KEY_APP}" "Install_Dir"
    ${If} $OldInstallPath != ""
        ${If} ${FileExists} "$OldInstallPath\${APP_EXE}"
            MessageBox MB_YESNO|MB_ICONQUESTION "$(STR_UPGRADE_ASK)" IDYES DoUpgrade IDNO AbortInstall
            AbortInstall:
                Abort   ; 用户选择“否”，退出安装
        ${EndIf}
        ; 注册表存在但主程序缺失，清理无效注册表
        DeleteRegKey ${REG_ROOT} "${REG_KEY_APP}"
        DeleteRegKey ${REG_ROOT} "${REG_KEY_UNINST}"
        StrCpy $OldInstallPath ""
    ${EndIf}

    ; 全新安装：设置默认路径
    StrCpy $INSTDIR "${INSTALL_DIR_DEFAULT}"
    Goto OnInitDone

DoUpgrade:
    StrCpy $IsUpgradeMode 1
    StrCpy $INSTDIR $OldInstallPath
    ; 强制关闭正在运行的进程
    ExecWait 'taskkill /f /im "${APP_EXE}"' $0
    Sleep 1500

OnInitDone:
FunctionEnd

; ============================================================
; 升级模式下跳过目录页（直接使用旧路径）
Function DirectoryPagePre
    ${If} $IsUpgradeMode == 1
        Abort
    ${EndIf}
FunctionEnd

; 离开目录页时检查目标目录是否非空
Function DirectoryPageLeave
    ; 如果是升级且路径未变，则信任旧目录，跳过检查
    ${If} $IsUpgradeMode == 1
        ${If} $INSTDIR == $OldInstallPath
            Return
        ${EndIf}
    ${EndIf}

    ; 全新安装 或 升级但用户修改了路径 → 检查目录是否为空
    ${If} ${FileExists} "$INSTDIR"
        ; 遍历目录，检查是否有非 "." 和 ".." 的条目
        FindFirst $0 $1 "$INSTDIR\*.*"
        StrCpy $2 0
        loop:
            StrCmp $1 "" done
            StrCmp $1 "." next
            StrCmp $1 ".." next
            StrCpy $2 1
            Goto done
            next:
            FindNext $0 $1
            Goto loop
        done:
        FindClose $0

        ${If} $2 == 1
            MessageBox MB_YESNO|MB_ICONEXCLAMATION "$(STR_DIR_NOT_EMPTY)" IDYES continue IDNO abort
            abort:
                Abort   ; 用户取消，返回目录页
            continue:
                ; 用户确认，继续安装
        ${EndIf}
    ${EndIf}
FunctionEnd

; ============================================================
; 安装区段
; ============================================================
Section "主程序文件" SecMain
    SectionIn RO
    SetOutPath "$INSTDIR"
    SetOverwrite on
    File /r "${DIST_DIR}\*"

    WriteUninstaller "$INSTDIR\uninstall.exe"

    ; 写入自定义注册表
    WriteRegStr ${REG_ROOT} "${REG_KEY_APP}" "Install_Root" "$INSTDIR\.."
    WriteRegStr ${REG_ROOT} "${REG_KEY_APP}" "Install_Dir" "$INSTDIR"
    WriteRegStr ${REG_ROOT} "${REG_KEY_APP}" "Version" "${APP_VERSION}"

    ; 写入 Windows 卸载信息
    WriteRegStr ${REG_ROOT} "${REG_KEY_UNINST}" "DisplayName" "${APP_DISPLAY_NAME}"
    WriteRegStr ${REG_ROOT} "${REG_KEY_UNINST}" "DisplayVersion" "${APP_VERSION}"
    WriteRegStr ${REG_ROOT} "${REG_KEY_UNINST}" "Publisher" "${APP_PUBLISHER}"
    WriteRegStr ${REG_ROOT} "${REG_KEY_UNINST}" "InstallLocation" "$INSTDIR"
    WriteRegStr ${REG_ROOT} "${REG_KEY_UNINST}" "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegStr ${REG_ROOT} "${REG_KEY_UNINST}" "HelpLink" "${APP_WEBSITE}"
    WriteRegStr ${REG_ROOT} "${REG_KEY_UNINST}" "DisplayIcon" "$INSTDIR\${APP_EXE}"
    WriteRegDWORD ${REG_ROOT} "${REG_KEY_UNINST}" "NoModify" 1
    WriteRegDWORD ${REG_ROOT} "${REG_KEY_UNINST}" "NoRepair" 1

    ; 估算安装大小（可选）
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    WriteRegDWORD ${REG_ROOT} "${REG_KEY_UNINST}" "EstimatedSize" $0
SectionEnd

Section "$(STR_DESKTOP)" SecDesktop
    Delete "$DESKTOP\${APP_DISPLAY_NAME}.lnk"
    CreateShortcut "$DESKTOP\${APP_DISPLAY_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}"
SectionEnd

Section "$(STR_STARTMENU)" SecStartMenu
    Delete "$SMPROGRAMS\${APP_DISPLAY_NAME}\*.lnk"
    CreateDirectory "$SMPROGRAMS\${APP_DISPLAY_NAME}"
    CreateShortcut "$SMPROGRAMS\${APP_DISPLAY_NAME}\${APP_DISPLAY_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}"
    CreateShortcut "$SMPROGRAMS\${APP_DISPLAY_NAME}\卸载 ${APP_DISPLAY_NAME}.lnk" "$INSTDIR\uninstall.exe"
SectionEnd

; 卸载区段
Section "Uninstall"
    ${If} $INSTDIR == ""
        MessageBox MB_OK|MB_ICONSTOP "无法确定安装目录，请手动删除程序文件夹。"
        Abort
    ${EndIf}

    ; 关闭程序
    ExecWait 'taskkill /f /im "${APP_EXE}"' $0
    Sleep 1500

    ; 询问是否保留用户配置
    MessageBox MB_YESNO|MB_ICONQUESTION "$(STR_UNINSTALL_KEEP_CFG)" IDNO PurgeConfig
    Goto AfterConfig
PurgeConfig:
    RMDir /r "$APPDATA\${APP_ID}"
    RMDir /REBOOTOK "$APPDATA\${APP_ID}"
AfterConfig:

    ; 删除快捷方式
    Delete "$DESKTOP\${APP_DISPLAY_NAME}.lnk"
    Delete "$SMPROGRAMS\${APP_DISPLAY_NAME}\*.lnk"
    RMDir "$SMPROGRAMS\${APP_DISPLAY_NAME}"

    ; 删除安装目录
    RMDir /r "$INSTDIR"
    RMDir /REBOOTOK "$INSTDIR"

    ; 删除注册表
    DeleteRegKey ${REG_ROOT} "${REG_KEY_UNINST}"
    DeleteRegKey ${REG_ROOT} "${REG_KEY_APP}"

    MessageBox MB_OK|MB_ICONINFORMATION "卸载完成，程序文件已清理完毕。"
SectionEnd
