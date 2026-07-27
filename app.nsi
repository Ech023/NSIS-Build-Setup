; ================================================================
; 通用 NSIS 安装脚本（覆盖静默升级 + 启动询问）
; 功能：全新安装显示完整向导；已安装时自动覆盖，跳过所有交互页，
;       但覆盖完成后询问是否立即启动程序。
; 使用：修改下方「用户配置区」即可。
; ================================================================

; 保存格式：UTF-8 with BOM
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"
!include "x64.nsh"
!include "WinVer.nsh"
RequestExecutionLevel admin

; ------------------- 压缩设置 -------------------
Allow7zipExtract false
SetCompressionLevel 9
SetCompressor /SOLID LZMA

; ================================================================
; 用户配置区（请按需修改）
; ================================================================
!define APP_DISPLAY_NAME "SourceGit"  ; 显示名称（界面、快捷方式）
!define APP_NAME         "SourceGit"  ; 内部名称（用于目录名、注册表键）
!define APP_ID           "com.github.SourceGit-scm.SourceGit" ; 唯一ID（建议使用网站倒序）
!define APP_EXE          "SourceGit.exe"  ; 主程序文件名
!define APP_VERSION      "2026.7.27.16"   ; 版本号（必须四段数字）
!define APP_PUBLISHER    "https://github.com/SourceGit-scm/"   ; 组织名
!define APP_WEBSITE      "https://github.com/SourceGit-scm/SourceGit"  ; 网站
!define APP_DATA_DIR     "$APPDATA\${APP_NAME}"  ; 应用数据路径

!define DIST_DIR         "D:\Fsoft\SourceGit" ; 源文件目录（所有待安装文件）
!define ICON_FILE        "icon.ico"  ; 图标文件（位于脚本同目录）
!define LICENSE_FILE     "LICENSE"   ; 许可文件（位于脚本同目录,若不需要可注释）

; 可选界面图片（若无请注释）  Header(150x57)  left(164x314)
;!define MUI_HEADERIMAGE
;!define MUI_HEADERIMAGE_RIGHT
;!define MUI_HEADERIMAGE_BITMAP "Header.bmp"
;!define MUI_WELCOMEFINISHPAGE_BITMAP   "left.bmp"
;!define MUI_UNWELCOMEFINISHPAGE_BITMAP "left.bmp"

; ================================================================
; 输出文件名与品牌
; ================================================================
OutFile "${APP_NAME}-${APP_VERSION}-Setup.exe"
BrandingText "${APP_NAME} ${APP_VERSION}"
Name "${APP_DISPLAY_NAME}"
Icon "${ICON_FILE}"

; ------------------- 文件版本信息 -------------------
VIProductVersion "${APP_VERSION}"
VIAddVersionKey "ProductName"     "${APP_DISPLAY_NAME}"
VIAddVersionKey "CompanyName"     "${APP_PUBLISHER}"
VIAddVersionKey "FileDescription" "${APP_NAME} Installer"
VIAddVersionKey "FileVersion"     "${APP_VERSION}"
VIAddVersionKey "ProductVersion"  "${APP_VERSION}"
VIAddVersionKey "LegalCopyright"  "Copyright © ${APP_PUBLISHER}"
VIAddVersionKey "URLInfoAbout"    "${APP_WEBSITE}"

; ------------------- 默认安装路径 -------------------
!define INSTALL_DIR_64  "$PROGRAMFILES64\${APP_NAME}"
!define INSTALL_DIR_32  "$PROGRAMFILES\${APP_NAME}"

; ------------------- 注册表键 -------------------
!define REG_ROOT          "HKLM"
!define REG_KEY_APP       "Software\${APP_ID}"
!define REG_KEY_UNINST    "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}"

; ------------------- MUI 界面样式 -------------------
!define MUI_ICON "${ICON_FILE}"
!define MUI_UNICON "${ICON_FILE}"
!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\${APP_EXE}"
!define MUI_FINISHPAGE_RUN_TEXT "启动 $(^Name)"
!define MUI_FINISHPAGE_RUN_CHECKED

; ------------------- 页面定义（升级时跳过交互页） -------------------
!define MUI_PAGE_CUSTOMFUNCTION_PRE WelcomePagePre
!insertmacro MUI_PAGE_WELCOME

!define MUI_PAGE_CUSTOMFUNCTION_PRE ComponentsPagePre
!insertmacro MUI_PAGE_COMPONENTS

!define MUI_PAGE_CUSTOMFUNCTION_PRE DirectoryPagePre
!insertmacro MUI_PAGE_DIRECTORY

; 许可页面（如需启用，取消注释并添加 Pre 函数）
!define MUI_PAGE_CUSTOMFUNCTION_PRE LicensePagePre
!insertmacro MUI_PAGE_LICENSE "${LICENSE_FILE}"

!insertmacro MUI_PAGE_INSTFILES

!define MUI_PAGE_CUSTOMFUNCTION_PRE FinishPagePre
!insertmacro MUI_PAGE_FINISH

; 卸载页面（不做改动）
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; ------------------- 语言与本地化 -------------------
!insertmacro MUI_LANGUAGE "SimpChinese"

LangString STR_DESKTOP    ${LANG_SIMPCHINESE} "创建桌面快捷方式"
LangString STR_STARTMENU  ${LANG_SIMPCHINESE} "创建开始菜单程序组"
LangString STR_UNINSTALL_KEEP_CFG ${LANG_SIMPCHINESE} "是否保留用户配置文件？$\r$\n选择「是」保留配置（位于 ${APP_DATA_DIR}），下次安装可恢复。$\r$\n选择「否」将同时清除所有用户配置。"
LangString STR_DIR_NOT_EMPTY ${LANG_SIMPCHINESE} "目标目录不为空！$\r$\n卸载时将删除整个目录，请确认该目录仅包含本应用的文件。$\r$\n是否继续？"
LangString STR_ADMIN_REQUIRED ${LANG_SIMPCHINESE} "需要管理员权限！$\r$\n请右键选择「以管理员身份运行」后重试。"
LangString STR_SPACE_NOT_ENOUGH ${LANG_SIMPCHINESE} "磁盘空间不足！$\r$\n需要至少 $RequiredSpace MB 的空间。$\r$\n当前可用空间：$AvailableSpace MB"
LangString STR_SOURCE_DIR_MISSING ${LANG_SIMPCHINESE} "源文件目录不存在！$\r$\n请检查 DIST_DIR 配置。"
LangString STR_SYSTEM_PATH_PROTECT ${LANG_SIMPCHINESE} "安装目录是系统关键路径，安装已取消以防止系统损坏。"

; ------------------- 全局变量 -------------------
Var IsUpgradeMode
Var OldInstallPath
Var OldVersion
Var RequiredSpace
Var AvailableSpace

; ================================================================
; 页面 Pre 函数（升级时跳过所有交互页）
; ================================================================
Function WelcomePagePre
    ${If} $IsUpgradeMode == 1
        Abort
    ${EndIf}
FunctionEnd

Function ComponentsPagePre
    ${If} $IsUpgradeMode == 1
        Abort
    ${EndIf}
FunctionEnd

Function DirectoryPagePre
    ${If} $IsUpgradeMode == 1
        Abort
    ${EndIf}
FunctionEnd

Function FinishPagePre
    ${If} $IsUpgradeMode == 1
        Abort
    ${EndIf}
FunctionEnd

; 许可页面（如需启用）
Function LicensePagePre
    ${If} $IsUpgradeMode == 1
        Abort
    ${EndIf}
FunctionEnd

; ================================================================
; 安装初始化（检测旧版本、强制杀进程、权限、磁盘）
; ================================================================
Function .onInit
    StrCpy $IsUpgradeMode 0
    StrCpy $OldInstallPath ""
    StrCpy $OldVersion ""

    ; 权限检测
    UserInfo::GetAccountType
    Pop $0
    ${If} $0 != "Admin"
        MessageBox MB_ICONEXCLAMATION|MB_OK "$(STR_ADMIN_REQUIRED)"
        Abort
    ${EndIf}

    ; 系统位数与默认路径
    ${If} ${RunningX64}
        SetRegView 64
        StrCpy $INSTDIR "${INSTALL_DIR_64}"
    ${Else}
        SetRegView 32
        StrCpy $INSTDIR "${INSTALL_DIR_32}"
    ${EndIf}

    ; 检测旧版本（尝试两种注册表视图）
    ${If} ${RunningX64}
        SetRegView 64
        ReadRegStr $OldInstallPath ${REG_ROOT} "${REG_KEY_APP}" "Install_Dir"
        ReadRegStr $OldVersion ${REG_ROOT} "${REG_KEY_APP}" "Version"
        ${If} $OldInstallPath == ""
            SetRegView 32
            ReadRegStr $OldInstallPath ${REG_ROOT} "${REG_KEY_APP}" "Install_Dir"
            ReadRegStr $OldVersion ${REG_ROOT} "${REG_KEY_APP}" "Version"
        ${EndIf}
    ${Else}
        SetRegView 32
        ReadRegStr $OldInstallPath ${REG_ROOT} "${REG_KEY_APP}" "Install_Dir"
        ReadRegStr $OldVersion ${REG_ROOT} "${REG_KEY_APP}" "Version"
    ${EndIf}

    ${If} $OldInstallPath != ""
        ${If} ${FileExists} "$OldInstallPath\${APP_EXE}"
            ; 直接进入升级（无询问）
            Goto DoUpgrade
        ${EndIf}
        ; 注册表无效，清理
        ${If} ${RunningX64}
            SetRegView 64
            DeleteRegKey ${REG_ROOT} "${REG_KEY_APP}"
            DeleteRegKey ${REG_ROOT} "${REG_KEY_UNINST}"
            SetRegView 32
            DeleteRegKey ${REG_ROOT} "${REG_KEY_APP}"
            DeleteRegKey ${REG_ROOT} "${REG_KEY_UNINST}"
        ${Else}
            SetRegView 32
            DeleteRegKey ${REG_ROOT} "${REG_KEY_APP}"
            DeleteRegKey ${REG_ROOT} "${REG_KEY_UNINST}"
        ${EndIf}
        StrCpy $OldInstallPath ""
        StrCpy $OldVersion ""
        ${If} ${RunningX64}
            SetRegView 64
            StrCpy $INSTDIR "${INSTALL_DIR_64}"
        ${Else}
            SetRegView 32
            StrCpy $INSTDIR "${INSTALL_DIR_32}"
        ${EndIf}
    ${EndIf}

    Goto OnInitDone

DoUpgrade:
    StrCpy $IsUpgradeMode 1
    StrCpy $INSTDIR $OldInstallPath
    
    DetailPrint "正在尝试自动关闭旧版本 ${APP_DISPLAY_NAME} 进程..."
    StrCpy $1 0

  KillLoop:
    IntOp $1 $1 + 1
    ExecWait 'taskkill /f /im "${APP_EXE}"' $0
    
    ${If} $0 == 0
        DetailPrint "已成功关闭旧版本进程 (尝试次数: $1)。"
        Goto KillDone
    ${ElseIf} $0 == 128
        DetailPrint "未检测到运行中的 ${APP_EXE}，无需关闭。"
        Goto KillDone
    ${Else}
        ${If} $1 < 3
            DetailPrint "终止进程失败 (错误码 $0)，等待 1 秒后重试 ($1/3)..."
            Sleep 1000
            Goto KillLoop
        ${Else}
            DetailPrint "多次尝试后仍无法自动终止进程 (错误码 $0)。"
            MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION "无法自动关闭 ${APP_EXE} 进程。$\r$\n请手动结束该进程后点击「重试」，或点击「取消」退出安装。" /SD IDCANCEL IDRETRY KillLoop IDCANCEL DoUpgradeAbort
        ${EndIf}
    ${EndIf}

  KillDone:
    Sleep 500
    Goto OnInitDone

  DoUpgradeAbort:
    Abort

OnInitDone:
    Call CheckDiskSpace
FunctionEnd

; ================================================================
; 磁盘空间检测
; ================================================================
Function CheckDiskSpace
    ${IfNot} ${FileExists} "${DIST_DIR}"
        MessageBox MB_ICONSTOP "$(STR_SOURCE_DIR_MISSING)"
        Abort
    ${EndIf}
    ${GetSize} "${DIST_DIR}" "/S=M" $RequiredSpace $1 $2
    IntOp $0 $RequiredSpace / 5
    IntOp $RequiredSpace $RequiredSpace + $0
    IntOp $RequiredSpace $RequiredSpace + 50

    ${DriveSpace} "$INSTDIR" "/S=M" $AvailableSpace
    ${If} $AvailableSpace == ""
        ${DriveSpace} "$INSTDIR\.." "/S=M" $AvailableSpace
    ${EndIf}

    ${If} $AvailableSpace < $RequiredSpace
        MessageBox MB_OK|MB_ICONSTOP "$(STR_SPACE_NOT_ENOUGH)"
        Abort
    ${EndIf}
FunctionEnd

; ================================================================
; 目录页离开时检查非空（仅全新安装时生效，升级时已跳过）
; ================================================================
Function DirectoryPageLeave
    ${If} $IsUpgradeMode == 1
        ${If} $INSTDIR == $OldInstallPath
            Return
        ${EndIf}
    ${EndIf}

    ${If} ${FileExists} "$INSTDIR"
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
                Abort
            continue:
        ${EndIf}
    ${EndIf}
FunctionEnd

; ================================================================
; 安装区段
; ================================================================
Section "主程序文件" SecMain
    SectionIn RO
    SetOutPath "$INSTDIR"
    SetOverwrite on  ; 强制覆盖所有文件

    File /r "${DIST_DIR}\*"

    WriteUninstaller "$INSTDIR\uninstall.exe"

    ; 写入注册表（使用正确视图）
    ${If} ${RunningX64}
        SetRegView 64
    ${Else}
        SetRegView 32
    ${EndIf}

    WriteRegStr ${REG_ROOT} "${REG_KEY_APP}" "Install_Root" "$INSTDIR\.."
    WriteRegStr ${REG_ROOT} "${REG_KEY_APP}" "Install_Dir" "$INSTDIR"
    WriteRegStr ${REG_ROOT} "${REG_KEY_APP}" "Version" "${APP_VERSION}"

    WriteRegStr ${REG_ROOT} "${REG_KEY_UNINST}" "DisplayName" "${APP_DISPLAY_NAME}"
    WriteRegStr ${REG_ROOT} "${REG_KEY_UNINST}" "DisplayVersion" "${APP_VERSION}"
    WriteRegStr ${REG_ROOT} "${REG_KEY_UNINST}" "Publisher" "${APP_PUBLISHER}"
    WriteRegStr ${REG_ROOT} "${REG_KEY_UNINST}" "InstallLocation" "$INSTDIR"
    WriteRegStr ${REG_ROOT} "${REG_KEY_UNINST}" "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegStr ${REG_ROOT} "${REG_KEY_UNINST}" "HelpLink" "${APP_WEBSITE}"
    WriteRegStr ${REG_ROOT} "${REG_KEY_UNINST}" "DisplayIcon" "$INSTDIR\${APP_EXE}"
    WriteRegDWORD ${REG_ROOT} "${REG_KEY_UNINST}" "NoModify" 1
    WriteRegDWORD ${REG_ROOT} "${REG_KEY_UNINST}" "NoRepair" 1

    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    WriteRegDWORD ${REG_ROOT} "${REG_KEY_UNINST}" "EstimatedSize" $0

    ; ===== 新增：覆盖安装完成后询问是否立即启动 =====
    ${If} $IsUpgradeMode == 1
        MessageBox MB_YESNO|MB_ICONQUESTION "安装完成，是否立即启动 $(^Name)？" /SD IDYES IDNO +2
            Exec '"$INSTDIR\${APP_EXE}"'
    ${EndIf}
SectionEnd

Section "$(STR_DESKTOP)" SecDesktop
    Delete "$DESKTOP\${APP_DISPLAY_NAME}.lnk"
    CreateShortcut "$DESKTOP\${APP_DISPLAY_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}"
SectionEnd

Section "$(STR_STARTMENU)" SecStartMenu
    Delete "$SMPROGRAMS\${APP_DISPLAY_NAME}\*.lnk"
    RMDir "$SMPROGRAMS\${APP_DISPLAY_NAME}"
    CreateDirectory "$SMPROGRAMS\${APP_DISPLAY_NAME}"
    CreateShortcut "$SMPROGRAMS\${APP_DISPLAY_NAME}\${APP_DISPLAY_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}"
    CreateShortcut "$SMPROGRAMS\${APP_DISPLAY_NAME}\卸载 ${APP_DISPLAY_NAME}.lnk" "$INSTDIR\uninstall.exe"
SectionEnd

; ================================================================
; 卸载区段（完全保留之前的所有修复）
; ================================================================
Section "Uninstall"
    ; 确定安装目录
    ${If} ${RunningX64}
        SetRegView 64
        ReadRegStr $INSTDIR ${REG_ROOT} "${REG_KEY_APP}" "Install_Dir"
        ${If} $INSTDIR == ""
            SetRegView 32
            ReadRegStr $INSTDIR ${REG_ROOT} "${REG_KEY_APP}" "Install_Dir"
        ${EndIf}
    ${Else}
        SetRegView 32
        ReadRegStr $INSTDIR ${REG_ROOT} "${REG_KEY_APP}" "Install_Dir"
    ${EndIf}
    ${If} $INSTDIR == ""
        StrCpy $INSTDIR "$EXEDIR"
    ${EndIf}

    ; 安全校验
    ${If} $INSTDIR == ""
        MessageBox MB_ICONSTOP "无法确定安装目录，请手动删除程序文件夹。"
        Abort
    ${EndIf}
    ${If} $INSTDIR == "C:\" 
    ${OrIf} $INSTDIR == "C:\Windows"
    ${OrIf} $INSTDIR == "C:\Windows\System32"
    ${OrIf} $INSTDIR == "C:\Windows\SysWOW64"
    ${OrIf} $INSTDIR == "D:\"
        MessageBox MB_ICONSTOP "$(STR_SYSTEM_PATH_PROTECT)"
        Abort
    ${EndIf}
    StrLen $0 $INSTDIR
    ${If} $0 < 3
        MessageBox MB_ICONSTOP "安装目录路径太短（可能是根目录），卸载取消以防止系统损坏。"
        Abort
    ${EndIf}

    ; 自清理
    ${If} $EXEPATH != "$TEMP\uninstall.exe"
        CopyFiles /SILENT "$EXEPATH" "$TEMP\uninstall.exe"
        ExecWait '"$TEMP\uninstall.exe" _?=$INSTDIR'
        Delete "$TEMP\uninstall.exe"
        Quit
    ${EndIf}

    ; 关闭进程
    DetailPrint "正在检查 ${APP_DISPLAY_NAME} 进程状态..."
    ExecWait 'taskkill /f /im "${APP_EXE}"' $0
    ${If} $0 == 0
        DetailPrint "已关闭进程。"
    ${ElseIf} $0 == 128
        DetailPrint "未检测到运行中的 ${APP_EXE}，继续卸载。"
    ${Else}
        DetailPrint "无法自动关闭 ${APP_EXE}（错误码 $0），将继续卸载，但可能残留文件。"
        MessageBox MB_OK|MB_ICONEXCLAMATION "无法关闭 ${APP_EXE} 进程。$\r$\n请手动结束该进程，否则部分文件可能无法删除。"
    ${EndIf}
    Sleep 1500

    ; 保留配置询问
    MessageBox MB_YESNO|MB_ICONQUESTION "$(STR_UNINSTALL_KEEP_CFG)" IDNO PurgeConfig
    Goto AfterConfig
PurgeConfig:
    ${If} ${FileExists} "${APP_DATA_DIR}"
        RMDir /r "${APP_DATA_DIR}"
        RMDir /REBOOTOK "${APP_DATA_DIR}"
    ${EndIf}
AfterConfig:

    ; 删除快捷方式
    Delete "$DESKTOP\${APP_DISPLAY_NAME}.lnk"
    Delete "$SMPROGRAMS\${APP_DISPLAY_NAME}\*.lnk"
    RMDir "$SMPROGRAMS\${APP_DISPLAY_NAME}"

    ; 删除安装目录
    RMDir /r "$INSTDIR"
    RMDir /REBOOTOK "$INSTDIR"

    ; 删除注册表（两种视图）
    ${If} ${RunningX64}
        SetRegView 64
        DeleteRegKey ${REG_ROOT} "${REG_KEY_UNINST}"
        DeleteRegKey ${REG_ROOT} "${REG_KEY_APP}"
        SetRegView 32
        DeleteRegKey ${REG_ROOT} "${REG_KEY_UNINST}"
        DeleteRegKey ${REG_ROOT} "${REG_KEY_APP}"
    ${Else}
        SetRegView 32
        DeleteRegKey ${REG_ROOT} "${REG_KEY_UNINST}"
        DeleteRegKey ${REG_ROOT} "${REG_KEY_APP}"
    ${EndIf}

    Delete "$EXEPATH"

    MessageBox MB_OK|MB_ICONINFORMATION "卸载完成，程序文件已清理完毕。"
SectionEnd
