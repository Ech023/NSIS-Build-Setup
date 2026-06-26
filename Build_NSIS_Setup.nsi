; ============================================================
; SourceGit NSIS 安装脚本 VSCode升级风格
; 升级覆盖不删除旧目录，保留第三方库/资源，安装提速；极简无报错路径逻辑
; ============================================================

; ===================== 1. 引入头文件 =====================
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"
!include "x64.nsh"

; ===================== 2. 全局压缩 =====================
SetCompressionLevel 9
SetCompressor /SOLID LZMA

; ===================== 3. MUI图标定义 =====================
!define MUI_ICON "SourceGit.ico"
!define MUI_UNICON "SourceGit.ico"
Icon "SourceGit.ico"

; ===================== 4. 核心配置区 =====================
!define APP_DISPLAY_NAME "SourceGit"
!define APP_NAME         "SourceGit"
!define APP_ID           "SourceGit.sourcegit-scm.com.github"
!define APP_EXE          "SourceGit.exe"
!define APP_VERSION      "2026.6.15.13"
!define APP_PUBLISHER    "SourceGit-SCM"
!define APP_WEBSITE      "https://github.com/sourcegit-scm/sourcegit"
!define DIST_DIR         "D:\soft\SourceGit"
!define REG_KEY          "Software\${APP_ID}"
!define APP_DATA_PATH    "$APPDATA\${APP_ID}"

; ===================== 5. MUI全局样式 =====================
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\${APP_EXE}"
!define MUI_FINISHPAGE_RUN_TEXT "$(STR_RUN_AFTER)"
!define MUI_FINISHPAGE_RUN_CHECKED

; ===================== 6. 打包基础信息 =====================
Name "${APP_DISPLAY_NAME}"
OutFile "${APP_NAME}-win32-${APP_VERSION}.exe"
Unicode True
RequestExecutionLevel admin
ShowInstDetails show
ShowUnInstDetails show

InstallDir "$PROGRAMFILES"
InstallDirRegKey HKLM "${REG_KEY}" "Install_Root"

; ===================== 7. 文件版本资源 =====================
VIProductVersion "${APP_VERSION}"
VIAddVersionKey "ProductName" "${APP_DISPLAY_NAME}"
VIAddVersionKey "CompanyName" "${APP_PUBLISHER}"
VIAddVersionKey "FileDescription" "${APP_DISPLAY_NAME} Setup Installer"
VIAddVersionKey "FileVersion" "${APP_VERSION}"
VIAddVersionKey "ProductVersion" "${APP_VERSION}"
VIAddVersionKey "LegalCopyright" "Copyright © ${APP_PUBLISHER}"
VIAddVersionKey "URLInfoAbout" "${APP_WEBSITE}"

; ===================== 8. 全局变量 =====================
Var IsUpgradeMode
Var OldInstallFullPath

; ===================== 9. 页面序列 =====================
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_COMPONENTS

!define MUI_PAGE_DIRECTORY_PRE DirectorySkipCheck
!insertmacro MUI_PAGE_DIRECTORY

!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; ===================== 10. 加载语言包 =====================
!insertmacro MUI_LANGUAGE "SimpChinese"

LangString STR_DESKTOP ${LANG_SIMPCHINESE} "创建桌面快捷方式"
LangString STR_STARTMENU ${LANG_SIMPCHINESE} "创建开始菜单程序组"
LangString STR_RUN_AFTER ${LANG_SIMPCHINESE} "安装完成后立即启动程序"
LangString STR_UPGRADE ${LANG_SIMPCHINESE} "检测到旧版本，将自动覆盖安装，程序会自动关闭，是否继续？"
LangString STR_UNINSTALL_TIP ${LANG_SIMPCHINESE} "卸载完成，程序文件已清理完毕。"
LangString STR_UNINSTALL_KEEP_CFG ${LANG_SIMPCHINESE} "是否保留用户配置文件？$\r$\n选择「是」保留配置，下次安装可恢复设置。$\r$\n选择「否」将同时清除所有用户数据。"
LangString STR_DELETE_OLD_FAILED ${LANG_SIMPCHINESE} "无法完全删除旧版本文件，请检查是否有程序仍在运行，然后重试。"

; ===================== 目录页前置钩子函数 =====================
Function DirectorySkipCheck
    ${If} $IsUpgradeMode == 1
        Abort
    ${EndIf}
FunctionEnd

; ===================== 安装初始化 .onInit 【重点：升级不再删除整个目录】 =====================
Function .onInit
    StrCpy $IsUpgradeMode 0
    StrCpy $OldInstallFullPath ""

    ReadRegStr $OldInstallFullPath HKLM "${REG_KEY}" "Install_Dir"

    ${If} $OldInstallFullPath != ""
        ${If} ${FileExists} "$OldInstallFullPath\${APP_EXE}"
            MessageBox MB_YESNO|MB_ICONQUESTION "$(STR_UPGRADE)" IDYES DoUpgrade
            Abort
        ${EndIf}
        StrCpy $OldInstallFullPath ""
    ${EndIf}

    ; 全新安装默认路径自带单层APP文件夹
    ${If} ${RunningX64}
        StrCpy $INSTDIR "$PROGRAMFILES64\${APP_NAME}"
    ${Else}
        StrCpy $INSTDIR "$PROGRAMFILES\${APP_NAME}"
    ${EndIf}
    Goto OnInitDone

DoUpgrade:
    StrCpy $IsUpgradeMode 1
    StrCpy $INSTDIR $OldInstallFullPath

    ; 仅关闭运行中的程序，不再删除整个安装目录，保留第三方资源/库文件
    ExecWait 'taskkill /f /im "${APP_EXE}"'
    Sleep 1500

    ; ========== 移除全部 RMDir 删除旧目录逻辑，直接跳过删除步骤 ==========

OnInitDone:
    ExecWait 'taskkill /f /im "${APP_EXE}"'
    Sleep 1000
FunctionEnd

; ===================== 极简目录处理，无任何复杂字符串逻辑，零编译报错 =====================
Function .onVerifyInstDir
    ${If} $IsUpgradeMode == 1
        Return
    ${EndIf}
    StrCpy $INSTDIR "$INSTDIR\${APP_NAME}"
FunctionEnd

; ===================== 主程序安装区段 =====================
Section "主程序文件" SecMain
    SectionIn RO

    SetOutPath "$INSTDIR"
    SetOverwrite on
    ; 直接覆盖写入，原有目录内第三方库、资源文件全部保留，仅更新安装包内文件
    File /r "${DIST_DIR}\*"

    WriteUninstaller "$INSTDIR\uninstall.exe"

    WriteRegStr HKLM "${REG_KEY}" "Install_Root" "$INSTDIR\.."
    WriteRegStr HKLM "${REG_KEY}" "Install_Dir" "$INSTDIR"
    WriteRegStr HKLM "${REG_KEY}" "Version" "${APP_VERSION}"

    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "DisplayName" "${APP_DISPLAY_NAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "DisplayVersion" "${APP_VERSION}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "Publisher" "${APP_PUBLISHER}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "InstallLocation" "$INSTDIR"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "HelpLink" "${APP_WEBSITE}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "DisplayIcon" "$INSTDIR\${APP_EXE}"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "NoModify" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "NoRepair" 1

    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}" "EstimatedSize" $0
SectionEnd

; 桌面快捷方式
Section "$(STR_DESKTOP)" SecDesktop
    Delete "$DESKTOP\${APP_DISPLAY_NAME}.lnk"
    CreateShortcut "$DESKTOP\${APP_DISPLAY_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}"
SectionEnd

; 开始菜单
Section "$(STR_STARTMENU)" SecStartMenu
    Delete "$SMPROGRAMS\${APP_DISPLAY_NAME}\*.lnk"
    CreateDirectory "$SMPROGRAMS\${APP_DISPLAY_NAME}"
    CreateShortcut "$SMPROGRAMS\${APP_DISPLAY_NAME}\${APP_DISPLAY_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}"
    CreateShortcut "$SMPROGRAMS\${APP_DISPLAY_NAME}\卸载 ${APP_DISPLAY_NAME}.lnk" "$INSTDIR\uninstall.exe"
SectionEnd

; 卸载区段（卸载时完整删除目录，清理干净，不影响升级逻辑）
Section "Uninstall"
    ${If} $INSTDIR == ""
        MessageBox MB_OK|MB_ICONSTOP "无法确定安装目录，请手动删除程序文件夹。"
        Abort
    ${EndIf}

    ExecWait 'taskkill /f /im "${APP_EXE}"'
    Sleep 1000

    MessageBox MB_YESNO|MB_ICONQUESTION "$(STR_UNINSTALL_KEEP_CFG)" IDNO PurgeConfig
    Goto AfterConfig

PurgeConfig:
    RMDir /r "${APP_DATA_PATH}"
    RMDir /REBOOTOK "${APP_DATA_PATH}"
AfterConfig:

    Delete "$DESKTOP\${APP_DISPLAY_NAME}.lnk"
    Delete "$SMPROGRAMS\${APP_DISPLAY_NAME}\*.lnk"
    RMDir "$SMPROGRAMS\${APP_DISPLAY_NAME}"

    RMDir /r "$INSTDIR"
    RMDir /REBOOTOK "$INSTDIR"

    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_ID}"
    DeleteRegKey HKLM "${REG_KEY}"

    MessageBox MB_OK|MB_ICONINFORMATION "$(STR_UNINSTALL_TIP)"
SectionEnd
